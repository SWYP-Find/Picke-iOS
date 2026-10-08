import ClassDomainInterface
import ComposableArchitecture
import PickeSharedUI

@Reducer
public struct MyClassFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public enum ViewState: Equatable {
      case loading
      case error
      case empty
      case loaded([ClassRoom])
    }

    public enum Progress: Hashable, CaseIterable {
      case all
      case open
      case closed
    }

    public var rooms: [ClassRoom] = []
    public var progress: Progress = .all
    public var isLoading = false
    public var isDeleting = false
    public var errorMessage: String?
    public var selectedRoomID: Int?
    @Presents public var modal: ClassModalFeature.State?
    @Presents public var customAlert: CustomAlertState<CustomAlertAction>?

    public init() {}

    public var viewState: ViewState {
      if errorMessage != nil && rooms.isEmpty {
        return .error
      }
      if isLoading && rooms.isEmpty {
        return .loading
      }
      let visible = visibleRooms
      return visible.isEmpty ? .empty : .loaded(visible)
    }

    public var visibleRooms: [ClassRoom] {
      rooms.filter { room in
        switch progress {
        case .all: true
        case .open: room.status == .open
        case .closed: room.status == .closed
        }
      }
    }
  }

  public enum Action: ViewAction {
    case view(View)
    case async(AsyncAction)
    case inner(InnerAction)
    case delegate(DelegateAction)
    case modal(PresentationAction<ClassModalFeature.Action>)
    case customAlert(PresentationAction<CustomAlertAction>)
  }

  public enum View {
    case onAppear
    case retryTapped
    case backTapped
    case progressTapped(State.Progress)
    case roomTapped(Int)
    case managementTapped(Int)
    case managementDismissed
    case editClassTapped
    case deleteTapped
    case deleteConfirmed
  }

  public enum AsyncAction: Equatable {
    case fetchRooms
    case delete(Int)
  }

  public enum InnerAction: Equatable {
    case roomsResponse(Result<[ClassRoom], ClassError>)
    case deleted(Result<Int, ClassError>)
  }

  public enum DelegateAction: Equatable {
    case dismiss
    case openRoom(ClassRoom)
    case openInformation(ClassRoom)
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
      case .modal(.presented(.dismissTapped)), .modal(.dismiss):
        state.modal = nil
        return .none
      case .modal:
        return .none
      case .customAlert(.presented(.confirmTapped)):
        let isDeleteConfirmation = state.customAlert?.style == .deleteConfirm
        state.customAlert = nil
        return isDeleteConfirmation ? handleViewAction(state: &state, action: .deleteConfirmed) : .none
      case .customAlert(.presented(.cancelTapped)), .customAlert(.dismiss):
        state.customAlert = nil
        return .none
      }
    }
    .ifLet(\.$modal, action: \.modal) {
      ClassModalFeature()
    }
    .ifLet(\.$customAlert, action: \.customAlert) {
      CustomConfirmAlert()
    }
  }
}

extension MyClassFeature {
  private func handleViewAction(state: inout State, action: View) -> Effect<Action> {
    switch action {
    case .onAppear, .retryTapped:
      return .send(.async(.fetchRooms))
    case .backTapped:
      return .send(.delegate(.dismiss))
    case let .progressTapped(progress):
      state.progress = progress
      return .none
    case let .roomTapped(id):
      guard let room = state.rooms.first(where: { $0.id == id }) else { return .none }
      return .send(.delegate(.openRoom(room)))
    case let .managementTapped(id):
      guard let room = state.rooms.first(where: { $0.id == id }), room.role == .owner else { return .none }
      state.selectedRoomID = id
      state.modal = .init(kind: .management)
      return .none
    case .managementDismissed:
      state.modal = nil
      return .none
    case .editClassTapped:
      guard let id = state.selectedRoomID,
            let room = state.rooms.first(where: { $0.id == id && $0.role == .owner })
      else { return .none }
      state.modal = nil
      return .send(.delegate(.openInformation(room)))
    case .deleteTapped:
      guard let id = state.selectedRoomID,
            state.rooms.contains(where: { $0.id == id && $0.role == .owner })
      else { return .none }
      state.modal = nil
      state.customAlert = CustomAlertState(
        title: "삭제 후에는 복구할 수 없어요.\n그럼에도 삭제하시겠습니까?",
        confirmTitle: "삭제하기",
        cancelTitle: "뒤로가기",
        isDestructive: true,
        style: .deleteConfirm
      )
      return .none
    case .deleteConfirmed:
      guard let id = state.selectedRoomID,
            !state.isDeleting,
            state.rooms.contains(where: { $0.id == id && $0.role == .owner })
      else { return .none }
      return .send(.async(.delete(id)))
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
    case let .delete(id):
      state.isDeleting = true
      return .run { [classUseCase] send in
        do {
          try await classUseCase.deleteClass(id: id)
          await send(.inner(.deleted(.success(id))))
        } catch {
          await send(.inner(.deleted(.failure(ClassError.from(error)))))
        }
      }
    }
  }

  private func handleInnerAction(state: inout State, action: InnerAction) -> Effect<Action> {
    switch action {
    case let .roomsResponse(.success(rooms)):
      state.isLoading = false
      state.rooms = rooms
    case let .roomsResponse(.failure(error)):
      state.isLoading = false
      state.errorMessage = error.message
    case let .deleted(.success(id)):
      state.isDeleting = false
      state.selectedRoomID = nil
      state.rooms.removeAll { $0.id == id }
      return .send(.async(.fetchRooms))
    case let .deleted(.failure(error)):
      state.isDeleting = false
      state.customAlert = .alert(title: "클래스를 삭제하지 못했어요", message: error.message)
    }
    return .none
  }
}
