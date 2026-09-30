import ClassDomainInterface
import ComposableArchitecture

@Reducer
public struct MyClassFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public enum Ownership: Equatable, CaseIterable {
      case all
      case created
      case joined
    }

    public enum Progress: Equatable, CaseIterable {
      case all
      case open
      case closed
    }

    public var rooms: [ClassRoom] = []
    public var ownership: Ownership = .all
    public var progress: Progress = .all
    public var isLoading = false
    public var errorMessage: String?

    public init() {}

    public var visibleRooms: [ClassRoom] {
      rooms.filter { room in
        let matchesOwnership: Bool = switch ownership {
        case .all: true
        case .created: room.role == .owner
        case .joined: room.role == .member
        }
        let matchesProgress: Bool = switch progress {
        case .all: true
        case .open: room.status == .open
        case .closed: room.status == .closed
        }
        return matchesOwnership && matchesProgress
      }
    }
  }

  public enum Action: ViewAction {
    case view(View)
    case async(AsyncAction)
    case inner(InnerAction)
    case delegate(DelegateAction)
  }

  public enum View {
    case onAppear
    case backTapped
    case ownershipTapped(State.Ownership)
    case progressTapped(State.Progress)
    case roomTapped(Int)
  }

  public enum AsyncAction: Equatable {
    case fetchRooms
  }

  public enum InnerAction: Equatable {
    case roomsResponse(Result<[ClassRoom], ClassError>)
  }

  public enum DelegateAction: Equatable {
    case dismiss
    case openRoom(ClassRoom)
  }

  @Dependency(\.classUseCase) private var classUseCase

  public var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
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

extension MyClassFeature {
  private func handleViewAction(state: inout State, action: View) -> Effect<Action> {
    switch action {
    case .onAppear:
      return .send(.async(.fetchRooms))
    case .backTapped:
      return .send(.delegate(.dismiss))
    case let .ownershipTapped(ownership):
      state.ownership = ownership
      return .none
    case let .progressTapped(progress):
      state.progress = progress
      return .none
    case let .roomTapped(id):
      guard let room = state.rooms.first(where: { $0.id == id }) else { return .none }
      return .send(.delegate(.openRoom(room)))
    }
  }

  private func handleAsyncAction(state: inout State, action: AsyncAction) -> Effect<Action> {
    switch action {
    case .fetchRooms:
      state.isLoading = true
      state.errorMessage = nil
      return .run { [classUseCase] send in
        let result = await Result {
          try await classUseCase.fetchMyClasses()
        }
        .mapError(ClassError.from)
        await send(.inner(.roomsResponse(result)))
      }
    }
  }

  private func handleInnerAction(state: inout State, action: InnerAction) -> Effect<Action> {
    state.isLoading = false
    switch action {
    case let .roomsResponse(.success(rooms)):
      state.rooms = rooms
    case let .roomsResponse(.failure(error)):
      state.errorMessage = String(describing: error)
    }
    return .none
  }
}
