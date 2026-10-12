//
//  MyClassFeature.swift
//  Class
//
//  Created by Picke on 10/11/26.
//

import ClassDomainInterface
import ComposableArchitecture
import PickeSharedUI

@Reducer
public struct MyClassFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public enum PendingConfirmation: Equatable {
      case delete(Int)
      case leave(Int)
    }

    public enum ViewState: Equatable {
      case loading
      case error
      case empty
      case loaded
    }

    public enum Progress: Hashable, CaseIterable {
      case all
      case open
      case closed
    }

    public var rooms: [ClassRoom] = []
    public var progress: Progress = .all
    public var viewState: ViewState = .loading
    public var isLoading = false
    public var isDeleting = false
    public var isLeaving = false
    public var leavingRoomID: Int?
    public var fetchGeneration = 0
    public var pendingConfirmation: PendingConfirmation?
    public var errorMessage: String?
    public var selectedRoomID: Int?
    @Presents public var modal: ClassModalFeature.State?
    @Presents public var customAlert: CustomAlertState<CustomAlertAction>?

    public init() {}

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
    case leaveTapped
    case leaveConfirmed
  }

  public enum AsyncAction: Equatable {
    case fetchRooms
    case delete(Int)
    case leave(Int)
  }

  public enum InnerAction: Equatable {
    case roomsResponse(Int, Result<[ClassRoom], ClassError>)
    case deleted(Result<Int, ClassError>)
    case left(Result<Int, ClassError>)
    case leaveCleanupCompleted(Int)
  }

  public enum DelegateAction: Equatable {
    case dismiss
    case openRoom(ClassRoom)
    case openInformation(ClassRoom)
    case left(Int)
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
      case let .modal(modalAction):
        return handleModalAction(state: &state, action: modalAction)
      case let .customAlert(alertAction):
        return handleCustomAlertAction(state: &state, action: alertAction)
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

extension MyClassFeature {
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
      state.customAlert = nil
      switch state.pendingConfirmation {
      case .delete:
        return handleViewAction(state: &state, action: .deleteConfirmed)
      case .leave:
        return handleViewAction(state: &state, action: .leaveConfirmed)
      case nil:
        return .none
      }
    case .presented(.cancelTapped), .dismiss:
      state.customAlert = nil
      state.pendingConfirmation = nil
      return .none
    }
  }

  private func handleViewAction(
    state: inout State,
    action: View
  ) -> Effect<Action> {
    switch action {
    case .onAppear, .retryTapped:
      guard !state.isLeaving else { return .none }
      return .send(.async(.fetchRooms))
    case .backTapped:
      guard !state.isLeaving else { return .none }
      return .send(.delegate(.dismiss))
    case let .progressTapped(progress):
      state.progress = progress
      if state.viewState == .loaded || state.viewState == .empty {
        state.viewState = state.visibleRooms.isEmpty ? .empty : .loaded
      }
      return .none
    case let .roomTapped(id):
      guard !state.isLeaving else { return .none }
      guard let room = state.rooms.first(where: { $0.id == id }) else { return .none }
      return .send(.delegate(.openRoom(room)))
    case let .managementTapped(id):
      guard !state.isLeaving, state.rooms.contains(where: { $0.id == id }) else { return .none }
      state.selectedRoomID = id
      state.modal = .init(kind: .management)
      return .none
    case .managementDismissed:
      guard !state.isLeaving else { return .none }
      state.modal = nil
      return .none
    case .editClassTapped:
      guard !state.isLeaving else { return .none }
      guard let id = state.selectedRoomID,
            let room = state.rooms.first(where: { $0.id == id && $0.role == .owner })
      else { return .none }
      state.modal = nil
      return .send(.delegate(.openInformation(room)))
    case .deleteTapped:
      guard !state.isLeaving, !state.isDeleting else { return .none }
      guard let id = state.selectedRoomID,
            state.rooms.contains(where: { $0.id == id && $0.role == .owner })
      else { return .none }
      state.modal = nil
      state.pendingConfirmation = .delete(id)
      state.customAlert = CustomAlertState(
        title: "삭제 후에는 복구할 수 없어요.\n그럼에도 삭제하시겠습니까?",
        confirmTitle: "삭제하기",
        cancelTitle: "뒤로가기",
        isDestructive: true,
        style: .deleteConfirm
      )
      return .none
    case .deleteConfirmed:
      guard case let .delete(id) = state.pendingConfirmation,
            !state.isDeleting,
            !state.isLeaving,
            state.rooms.contains(where: { $0.id == id && $0.role == .owner })
      else { return .none }
      state.pendingConfirmation = nil
      state.modal = nil
      return .send(.async(.delete(id)))
    case .leaveTapped:
      guard !state.isLeaving, !state.isDeleting,
            let id = state.selectedRoomID,
            state.rooms.contains(where: { $0.id == id && $0.role == .member })
      else { return .none }
      state.modal = nil
      state.pendingConfirmation = .leave(id)
      state.customAlert = CustomAlertState(
        title: "클래스에서 나가시겠습니까?",
        message: "나간 후에는 데이터를 복구할 수 없어요.",
        confirmTitle: "나가기",
        cancelTitle: "뒤로가기",
        isDestructive: true,
        style: .deleteConfirm
      )
      return .none
    case .leaveConfirmed:
      guard case let .leave(id) = state.pendingConfirmation,
            !state.isLeaving,
            !state.isDeleting,
            state.rooms.contains(where: { $0.id == id && $0.role == .member })
      else { return .none }
      state.pendingConfirmation = nil
      state.modal = nil
      return .send(.async(.leave(id)))
    }
  }

  private func handleAsyncAction(
    state: inout State,
    action: AsyncAction
  ) -> Effect<Action> {
    switch action {
    case .fetchRooms:
      guard !state.isLeaving, !state.isDeleting else { return .none }
      state.fetchGeneration += 1
      let generation = state.fetchGeneration
      state.isLoading = true
      state.errorMessage = nil
      if state.viewState == .loading || state.viewState == .error {
        state.viewState = .loading
      }
      return .run { [classUseCase] send in
        let result = await Result {
          try await classUseCase.fetchMyClasses()
        }
        .mapError(ClassError.from)
        await send(.inner(.roomsResponse(generation, result)))
      }
    case let .delete(id):
      guard !state.isLeaving, !state.isDeleting,
            state.rooms.contains(where: { $0.id == id && $0.role == .owner })
      else { return .none }
      state.isDeleting = true
      state.fetchGeneration += 1
      state.isLoading = false
      return .run { [classUseCase] send in
        do {
          try await classUseCase.deleteClass(id: id)
          await send(.inner(.deleted(.success(id))))
        } catch {
          await send(.inner(.deleted(.failure(ClassError.from(error)))))
        }
      }
    case let .leave(id):
      guard !state.isLeaving, !state.isDeleting,
            state.rooms.contains(where: { $0.id == id && $0.role == .member })
      else { return .none }
      state.isLeaving = true
      state.leavingRoomID = id
      state.fetchGeneration += 1
      state.isLoading = false
      return .run { [classUseCase] send in
        do {
          try await classUseCase.leaveClass(id: id)
          await send(.inner(.left(.success(id))))
        } catch {
          await send(.inner(.left(.failure(ClassError.from(error)))))
        }
      }
    }
  }

  private func handleInnerAction(
    state: inout State,
    action: InnerAction
  ) -> Effect<Action> {
    switch action {
    case let .roomsResponse(generation, .success(rooms)):
      guard generation == state.fetchGeneration, !state.isLeaving, !state.isDeleting else { return .none }
      state.isLoading = false
      state.rooms = rooms
      state.viewState = state.visibleRooms.isEmpty ? .empty : .loaded
    case let .roomsResponse(generation, .failure(error)):
      guard generation == state.fetchGeneration, !state.isLeaving, !state.isDeleting else { return .none }
      state.isLoading = false
      state.errorMessage = error.message
      if state.viewState == .loading {
        state.viewState = .error
      }
    case let .deleted(.success(id)):
      state.isDeleting = false
      state.selectedRoomID = nil
      state.rooms.removeAll { $0.id == id }
      state.viewState = state.visibleRooms.isEmpty ? .empty : .loaded
      return .send(.async(.fetchRooms))
    case let .deleted(.failure(error)):
      state.isDeleting = false
      state.customAlert = .alert(title: "클래스를 삭제하지 못했어요", message: error.message)
    case let .left(.success(id)):
      guard state.isLeaving, state.leavingRoomID == id else { return .none }
      return .send(.delegate(.left(id)))
    case let .left(.failure(error)):
      guard state.isLeaving else { return .none }
      state.isLeaving = false
      state.leavingRoomID = nil
      state.customAlert = .alert(title: "클래스에서 나가지 못했어요", message: error.message)
    case let .leaveCleanupCompleted(id):
      guard state.isLeaving, state.leavingRoomID == id else { return .none }
      state.rooms.removeAll { $0.id == id }
      state.viewState = state.visibleRooms.isEmpty ? .empty : .loaded
      state.selectedRoomID = nil
      state.isLeaving = false
      state.leavingRoomID = nil
      state.fetchGeneration += 1
    }
    return .none
  }
}
