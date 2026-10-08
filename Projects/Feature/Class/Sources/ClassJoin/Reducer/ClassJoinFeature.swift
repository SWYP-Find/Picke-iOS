import ClassDomainInterface
import ComposableArchitecture
import Foundation

@Reducer
public struct ClassJoinFeature {
  @Dependency(\.classUseCase) private var classUseCase
  @Dependency(\.classMockRepository) private var classMockRepository

  public init() {}

  public enum Mode: Equatable {
    case code
    case nickname
    case ownerName
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
      let hasName = !nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      return (mode == .nickname || mode == .ownerName) && preview != nil && hasName && !isLoading
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

  @CasePathable
  public enum AsyncAction: Equatable {
    case find(String)
    case join(joinCode: String, nickname: String)
    case nameOwner(roomID: Int, nickname: String)
  }

  @CasePathable
  public enum InnerAction: Equatable {
    case found(Result<ClassRoom, ClassError>)
    case joined(Result<ClassRoom, ClassError>, nickname: String)
    case ownerNamed(Result<ClassRoom, ClassError>)
  }

  @CasePathable
  public enum DelegateAction: Equatable {
    case dismiss
    case found(ClassRoom)
    case joined(ClassRoom, nickname: String)
    case ownerNamed(ClassRoom)
  }

  nonisolated enum CancelID: Hashable {
    case find
    case join
    case nameOwner
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
      switch state.mode {
      case .nickname:
        return .send(.async(.join(joinCode: room.joinCode, nickname: nickname)))
      case .ownerName:
        return .send(.async(.nameOwner(roomID: room.id, nickname: nickname)))
      case .code:
        return .none
      }
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

    case let .nameOwner(roomID, nickname):
      state.isLoading = true
      state.errorMessage = nil
      return .run { [classMockRepository] send in
        let result = await Result { () async throws -> ClassRoom in
          guard let classMockRepository else { throw ClassError.unknown("이름을 저장할 수 없어요.") }
          let memberID = try await classMockRepository.currentMemberID(roomID: roomID)
          _ = try await classMockRepository.updateDisplayName(
            roomID: roomID,
            memberID: memberID,
            currentMemberID: memberID,
            name: nickname
          )
          let rooms = try await classMockRepository.fetchMyClasses()
          guard let room = rooms.first(where: { $0.id == roomID }) else { throw ClassError.invalidCode }
          return room
        }
        .mapError(ClassError.from)
        await send(.inner(.ownerNamed(result)))
      }
      .cancellable(id: CancelID.nameOwner, cancelInFlight: true)
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

    case let .ownerNamed(.success(room)):
      state.preview = nil
      return .send(.delegate(.ownerNamed(room)))

    case let .found(.failure(error)), let .joined(.failure(error), _), let .ownerNamed(.failure(error)):
      state.errorMessage = error.message
      return .none
    }
  }
}
