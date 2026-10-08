import ClassDomainInterface
import ComposableArchitecture
import Foundation

@Reducer
public struct ClassJoinFeature {
  @Dependency(\.classUseCase) private var classUseCase

  public init() {}

  public enum Mode: Equatable {
    case code
    case nickname
  }

  @ObservableState
  public struct State: Equatable {
    public var mode: Mode
    public var joinCode = ""
    public var nickname = ""
    public var preview: ClassRoom?
    public var isLoading = false
    public var errorMessage: String?

    public init(mode: Mode = .code, preview: ClassRoom? = nil) {
      self.mode = mode
      self.preview = preview
    }

    public var canFindClass: Bool {
      mode == .code && joinCode.count == 6 && !isLoading
    }

    public var canJoin: Bool {
      mode == .nickname && preview != nil && !nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        .isEmpty && !isLoading
    }
  }

  public enum Action: ViewAction, BindableAction {
    case binding(BindingAction<State>)
    case view(View)
    case async(AsyncAction)
    case inner(InnerAction)
    case delegate(DelegateAction)
  }

  @CasePathable
  public enum View {
    case backTapped
    case findTapped
    case joinTapped
  }

  public enum AsyncAction: Equatable {
    case find(String)
    case join(joinCode: String, nickname: String)
  }

  public enum InnerAction: Equatable {
    case found(Result<ClassRoom, ClassError>)
    case joined(Result<ClassRoom, ClassError>, nickname: String)
  }

  @CasePathable
  public enum DelegateAction: Equatable {
    case dismiss
    case found(ClassRoom)
    case joined(ClassRoom, nickname: String)
  }

  nonisolated enum CancelID: Hashable {
    case find
    case join
  }

  public var body: some Reducer<State, Action> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .binding:
        state.joinCode = String(
          state.joinCode.uppercased()
            .filter { $0.isASCII && ($0.isLetter || $0.isNumber) }
            .prefix(6)
        )
        state.errorMessage = nil
        return .none

      case let .view(viewAction):
        return handleViewAction(state: &state, action: viewAction)

      case let .async(asyncAction):
        return handleAsyncAction(state: &state, action: asyncAction)

      case let .inner(innerAction):
        return handleInnerAction(state: &state, action: innerAction)

      case .delegate:
        return .none
      }
    }
  }
}

private extension ClassJoinFeature {
  func handleViewAction(state: inout State, action: View) -> Effect<Action> {
    switch action {
    case .backTapped:
      return .send(.delegate(.dismiss))

    case .findTapped:
      guard state.canFindClass else { return .none }
      return .send(.async(.find(state.joinCode)))

    case .joinTapped:
      guard state.canJoin, let room = state.preview else { return .none }
      let nickname = state.nickname.trimmingCharacters(in: .whitespacesAndNewlines)
      return .send(.async(.join(joinCode: room.joinCode, nickname: nickname)))
    }
  }

  func handleAsyncAction(state: inout State, action: AsyncAction) -> Effect<Action> {
    switch action {
    case let .find(code):
      state.isLoading = true
      state.errorMessage = nil
      return .run { [classUseCase] send in
        let result = await Result {
          try await classUseCase.fetchClass(joinCode: code)
        }
        .mapError(ClassError.from)
        await send(.inner(.found(result)))
      }
      .cancellable(id: CancelID.find, cancelInFlight: true)

    case let .join(code, nickname):
      state.isLoading = true
      state.errorMessage = nil
      return .run { [classUseCase] send in
        let result = await Result {
          try await classUseCase.joinClass(joinCode: code, nickname: nickname)
        }
        .mapError(ClassError.from)
        await send(.inner(.joined(result, nickname: nickname)))
      }
      .cancellable(id: CancelID.join, cancelInFlight: true)
    }
  }

  func handleInnerAction(state: inout State, action: InnerAction) -> Effect<Action> {
    state.isLoading = false
    switch action {
    case let .found(.success(room)):
      return .send(.delegate(.found(room)))

    case let .joined(.success(room), nickname):
      state.preview = nil
      return .send(.delegate(.joined(room, nickname: nickname)))

    case let .found(.failure(error)), let .joined(.failure(error), _):
      state.errorMessage = error.message
      return .none
    }
  }
}
