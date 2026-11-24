//
//  ClassDetailFeature.swift
//  Class
//
//  Created by Picke on 10/11/26.
//

import ClassDomainInterface
import ComposableArchitecture
import Foundation
import PickeCoreUtility
import PickeSharedUI

@Reducer
public struct ClassDetailFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public enum ViewState: Equatable {
      case loading
      case error
      case loaded
    }

    public var room: ClassRoom
    public let instanceID: UUID
    public var viewState: ViewState = .loaded
    public var loadErrorMessage: String?
    public var activeLoadRequestID: UUID?
    @Presents public var modal: ClassModalFeature.State?
    @Presents public var customAlert: CustomAlertState<CustomAlertAction>?
    public var isLoading = false
    public var errorMessage: String?
    public var toastMessage: String?
    public var isLeaveConfirmation = false

    public init(room: ClassRoom) {
      @Dependency(\.uuid) var uuid
      self.room = room
      instanceID = uuid()
    }

    /// 마감일을 끈 클래스는 `.distantFuture` 로 만들어지므로 날짜 대신 안내 문구를 보여준다.
    public var deadlineText: String {
      guard room.deadline != .distantFuture else { return "마감일 없음" }
      return room.deadline.formatted(.dottedDateTimeWithWeekday) + "까지"
    }

    public var canParticipateInBattle: Bool {
      room.role != .owner || room.ownerParticipates
    }
  }

  public enum Action: ViewAction {
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
    case retryTapped
    case membersTapped
    case battleTapped
    case reportTapped
    case managementTapped
    case managementDismissed
    case codeTapped
    case codeDismissed
    case deadlineTapped
    case editTapped
    case shareTapped
    case deleteTapped
    case deleteConfirmed
    case leaveTapped
    case leaveConfirmed
    case toastShown
  }

  public enum DelegateAction: Equatable {
    case dismiss
    case retryRequested(roomID: Int, instanceID: UUID)
    case openMembers(ClassRoom)
    case openBattle(ClassRoom)
    case openClosedBattle(ClassRoom)
    case openReport(ClassRoom)
    case openEdit(ClassRoom)
    case openShare(ClassRoom)
    case deleted(Int)
    case left(Int)
  }

  public enum AsyncAction: Equatable {
    case delete(Int)
    case leave(Int)
  }

  public enum InnerAction: Equatable {
    case deleted(Int, ClassError?)
    case left(Int, ClassError?)
  }

  @Dependency(\.classRoomUseCase) private var classRoomUseCase

  public var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case let .view(viewAction):
        return handleViewAction(state: &state, action: viewAction)
      case let .async(asyncAction):
        return handleAsyncAction(state: &state, action: asyncAction)
      case let .inner(innerAction):
        return handleInnerAction(state: &state, action: innerAction)
      case let .modal(modalAction):
        return handleModalAction(state: &state, action: modalAction)
      case let .customAlert(alertAction):
        return handleCustomAlertAction(state: &state, action: alertAction)
      case let .dataUpdated(room):
        state.room = room
        state.viewState = .loaded
        state.activeLoadRequestID = nil
        state.loadErrorMessage = nil
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

// MARK: - Action Handlers

extension ClassDetailFeature {
  private func handleModalAction(
    state: inout State,
    action: PresentationAction<ClassModalFeature.Action>
  ) -> Effect<Action> {
    switch action {
    case .presented(.dismissTapped), .dismiss:
      state.modal = nil
      return .none
    }
  }

  private func handleCustomAlertAction(
    state: inout State,
    action: PresentationAction<CustomAlertAction>
  ) -> Effect<Action> {
    switch action {
    case .presented(.confirmTapped):
      let isConfirmation = state.customAlert?.style == .deleteConfirm
      let isLeave = state.isLeaveConfirmation
      state.customAlert = nil
      state.errorMessage = nil
      state.isLeaveConfirmation = false
      guard isConfirmation else { return .none }
      return handleViewAction(state: &state, action: isLeave ? .leaveConfirmed : .deleteConfirmed)
    case .presented(.cancelTapped), .dismiss:
      state.customAlert = nil
      state.errorMessage = nil
      state.isLeaveConfirmation = false
      return .none
    }
  }

  private func handleViewAction(
    state: inout State,
    action: View
  ) -> Effect<Action> {
    switch action {
    case .backTapped:
      return .send(.delegate(.dismiss))
    case .retryTapped:
      guard state.viewState == .error else { return .none }
      return .send(.delegate(.retryRequested(
        roomID: state.room.id,
        instanceID: state.instanceID
      )))
    case .membersTapped:
      guard state.viewState == .loaded else { return .none }
      return .send(.delegate(.openMembers(state.room)))
    case .battleTapped:
      guard state.viewState == .loaded else { return .none }
      // Android ClassDetailViewModel.startBattle: 마감 → 미참여 운영자 순으로 토스트를 띄운다.
      guard state.room.status == .open else {
        state.toastMessage = "참여 기간이 마감되었어요."
        return .none
      }
      guard state.canParticipateInBattle else {
        state.toastMessage = "운영자 참여를 켜지 않은 클래스라 배틀에 참여할 수 없어요."
        return .none
      }
      return .send(.delegate(.openBattle(state.room)))
    case .reportTapped:
      guard state.viewState == .loaded else { return .none }
      return .send(.delegate(.openReport(state.room)))
    case .managementTapped:
      guard state.viewState == .loaded else { return .none }
      state.modal = .init(kind: .management)
      return .none
    case .managementDismissed:
      state.modal = nil
      return .none
    case .codeTapped:
      guard state.viewState == .loaded else { return .none }
      state.modal = .init(kind: .code)
      return .none
    case .codeDismissed:
      state.modal = nil
      return .none
    case .deadlineTapped, .editTapped:
      // Android DeadlineEditClick·ManageEditClick 모두 ClassEdit 화면으로 이동한다.
      guard state.viewState == .loaded else { return .none }
      guard state.room.role == .owner else { return .none }
      state.modal = nil
      return .send(.delegate(.openEdit(state.room)))
    case .shareTapped:
      guard state.viewState == .loaded else { return .none }
      state.modal = nil
      return .send(.delegate(.openShare(state.room)))
    case .leaveTapped:
      guard state.viewState == .loaded else { return .none }
      guard state.room.role == .member else { return .none }
      state.modal = nil
      state.isLeaveConfirmation = true
      state.customAlert = CustomAlertState(
        title: "클래스에서 나가면 해당 클래스의 활동과 결과를 더 이상 확인할 수 없어요.",
        confirmTitle: "나가기",
        cancelTitle: "뒤로가기",
        isDestructive: true,
        style: .deleteConfirm
      )
      return .none
    case .leaveConfirmed:
      guard state.room.role == .member, !state.isLoading else { return .none }
      state.customAlert = nil
      return .send(.async(.leave(state.room.id)))
    case .toastShown:
      state.toastMessage = nil
      return .none
    case .deleteTapped:
      guard state.viewState == .loaded else { return .none }
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
    case let .delete(id):
      return .run { [classRoomUseCase] send in
        do {
          try await classRoomUseCase.deleteClass(id: id)
          await send(.inner(.deleted(id, nil)))
        } catch {
          await send(.inner(.deleted(id, ClassError.from(error))))
        }
      }
    case let .leave(id):
      return .run { [classRoomUseCase] send in
        do {
          try await classRoomUseCase.leaveClass(id: id)
          await send(.inner(.left(id, nil)))
        } catch {
          await send(.inner(.left(id, ClassError.from(error))))
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
    case let .deleted(_, .some(error)), let .left(_, .some(error)):
      state.errorMessage = error.localizedDescription
      state.customAlert = .alert(
        title: "요청을 완료하지 못했어요",
        message: error.localizedDescription
      )
      return .none
    case let .deleted(id, .none):
      return .send(.delegate(.deleted(id)))
    case let .left(id, .none):
      return .send(.delegate(.left(id)))
    }
  }
}
