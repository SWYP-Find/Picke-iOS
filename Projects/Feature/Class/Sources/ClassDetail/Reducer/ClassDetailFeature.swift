import ClassDomainInterface
import ComposableArchitecture
import Foundation
import PickeCoreUtility
import PickeSharedUI

@Reducer
public struct ClassDetailFeature {
  @Dependency(\.classUseCase) private var classUseCase

  public init() {}

  @ObservableState
  public struct State: Equatable {
    public var room: ClassRoom
    public var deadline: Date
    public var draftDeadline: Date
    @Presents public var modal: ClassModalFeature.State?
    @Presents public var customAlert: CustomAlertState<CustomAlertAction>?
    public var isLoading = false
    public var errorMessage: String?

    public init(room: ClassRoom) {
      self.room = room
      deadline = room.deadline
      draftDeadline = room.deadline
    }

    /// 마감일을 끈 클래스는 `.distantFuture` 로 만들어지므로 날짜 대신 안내 문구를 보여준다.
    public var deadlineText: String {
      guard deadline != .distantFuture else { return "마감일 없음" }
      return deadline.formatted(.dottedDateTimeWithWeekday) + "까지"
    }
  }

  public enum Action: ViewAction, BindableAction {
    case binding(BindingAction<State>)
    case view(View)
    case async(AsyncAction)
    case inner(InnerAction)
    case modal(PresentationAction<ClassModalFeature.Action>)
    case customAlert(PresentationAction<CustomAlertAction>)
    case dataUpdated(ClassRoom)
    case delegate(DelegateAction)
  }

  public enum View {
    case backTapped
    case membersTapped
    case battleTapped
    case reportTapped
    case managementTapped
    case managementDismissed
    case codeTapped
    case codeDismissed
    case deadlineTapped
    case deadlineSaved
    case deleteTapped
    case deleteConfirmed
  }

  public enum DelegateAction: Equatable {
    case dismiss
    case openMembers(ClassRoom)
    case openBattle(ClassBattleSummary)
    case openReport(ClassRoom)
    case deleted(Int)
  }

  public enum AsyncAction: Equatable {
    case updateDeadline(Int, Date)
    case delete(Int)
  }

  public enum InnerAction: Equatable {
    case deadlineUpdated(Result<ClassRoom, ClassError>)
    case deleted(Int, ClassError?)
  }

  public var body: some Reducer<State, Action> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .binding:
        return .none
      case let .view(viewAction):
        return handleViewAction(state: &state, action: viewAction)
      case let .async(asyncAction):
        return handleAsyncAction(state: &state, action: asyncAction)
      case let .inner(innerAction):
        return handleInnerAction(state: &state, action: innerAction)
      case .modal(.presented(.dismissTapped)), .modal(.dismiss):
        state.modal = nil
        return .none
      case .modal:
        return .none
      case let .customAlert(alertAction):
        switch alertAction {
        case .presented(.confirmTapped):
          let isDeleteConfirmation = state.customAlert?.style == .deleteConfirm
          state.customAlert = nil
          state.errorMessage = nil
          return isDeleteConfirmation
            ? handleViewAction(state: &state, action: .deleteConfirmed)
            : .none
        case .presented(.cancelTapped), .dismiss:
          state.customAlert = nil
          state.errorMessage = nil
          return .none
        }
      case let .dataUpdated(room):
        state.room = room
        state.deadline = room.deadline
        state.draftDeadline = room.deadline
        return .none
      case .delegate:
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

extension ClassDetailFeature {
  private func handleViewAction(state: inout State, action: View) -> Effect<Action> {
    switch action {
    case .backTapped:
      return .send(.delegate(.dismiss))
    case .membersTapped:
      return .send(.delegate(.openMembers(state.room)))
    case .battleTapped:
      #if DEBUG
        if ClassBattleSummary.mocks.contains(where: { $0.id == state.room.battle.id }) {
          state.customAlert = .alert(
            title: "배틀을 준비하고 있어요",
            message: "이 클래스의 배틀은 아직 참여할 수 없어요."
          )
          return .none
        }
      #endif
      return .send(.delegate(.openBattle(state.room.battle)))
    case .reportTapped:
      return .send(.delegate(.openReport(state.room)))
    case .managementTapped:
      guard state.room.role == .owner else { return .none }
      state.modal = .init(kind: .management)
      return .none
    case .managementDismissed:
      state.modal = nil
      return .none
    case .codeTapped:
      state.modal = .init(kind: .code)
      return .none
    case .codeDismissed:
      state.modal = nil
      return .none
    case .deadlineTapped:
      guard state.room.role == .owner else { return .none }
      state.modal = .init(kind: .deadline)
      state.draftDeadline = state.deadline
      return .none
    case .deadlineSaved:
      guard !state.isLoading else { return .none }
      return .send(.async(.updateDeadline(state.room.id, state.draftDeadline)))
    case .deleteTapped:
      guard state.room.role == .owner else { return .none }
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
      guard state.room.role == .owner, !state.isLoading else { return .none }
      state.customAlert = nil
      return .send(.async(.delete(state.room.id)))
    }
  }

  private func handleAsyncAction(
    state: inout State,
    action: AsyncAction
  ) -> Effect<Action> {
    state.isLoading = true
    state.errorMessage = nil
    switch action {
    case let .updateDeadline(id, deadline):
      return .run { [classUseCase] send in
        let result = await Result { try await classUseCase.updateDeadline(id: id, deadline: deadline) }
          .mapError(ClassError.from)
        await send(.inner(.deadlineUpdated(result)))
      }
    case let .delete(id):
      return .run { [classUseCase] send in
        do {
          try await classUseCase.deleteClass(id: id)
          await send(.inner(.deleted(id, nil)))
        } catch {
          await send(.inner(.deleted(id, ClassError.from(error))))
        }
      }
    }
  }

  private func handleInnerAction(
    state: inout State,
    action: InnerAction
  ) -> Effect<Action> {
    state.isLoading = false
    switch action {
    case let .deadlineUpdated(.success(room)):
      state.room = room
      state.deadline = room.deadline
      state.modal = nil
      return .none
    case let .deadlineUpdated(.failure(error)), let .deleted(_, .some(error)):
      state.errorMessage = error.localizedDescription
      state.customAlert = .alert(
        title: "요청을 완료하지 못했어요",
        message: error.localizedDescription
      )
      return .none
    case let .deleted(id, .none):
      return .send(.delegate(.deleted(id)))
    }
  }
}
