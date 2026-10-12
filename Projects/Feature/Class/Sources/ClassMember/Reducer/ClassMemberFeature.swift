//
//  ClassMemberFeature.swift
//  Class
//
//  Created by Picke on 10/11/26.
//

import ClassDomainInterface
import ComposableArchitecture
import Foundation
import PickeSharedUI

@Reducer
public struct ClassMemberFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public enum ViewState: Equatable {
      case loading
      case error
      case empty
      case noSearchResults
      case loaded
    }

    public let instanceID: UUID
    public var room: ClassRoom
    public var members: [ClassMember]
    public var currentMemberID: Int
    public var viewState: ViewState
    public var isLoading = false
    public var loadErrorMessage: String?
    public var activeLoadRequestID: UUID?
    public var searchText = ""
    public var draftName = ""
    public var pendingRemovalID: Int?
    public var errorMessage: String?
    public var isSaving = false
    public var appliedFilter = ClassMemberFilterFeature.State()
    public var hasAppliedSort = false
    @Presents public var filter: ClassMemberFilterFeature.State?
    @Presents public var editName: ClassMemberEditNameFeature.State?
    @Presents public var customAlert: CustomAlertState<CustomAlertAction>?

    public init(
      room: ClassRoom,
      members: [ClassMember] = [],
      currentMemberID: Int = 1,
      instanceID: UUID? = nil,
      preloadedViewState: ViewState? = nil
    ) {
      @Dependency(\.uuid) var uuid
      self.instanceID = instanceID ?? uuid()
      self.room = room
      self.members = members
      self.currentMemberID = currentMemberID
      viewState = preloadedViewState ?? .loading
    }

    public var visibleMembers: [ClassMember] {
      let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
      let filteredMembers = query.isEmpty
        ? members
        : members.filter { $0.name.localizedCaseInsensitiveContains(query) }

      if hasAppliedSort, appliedFilter.sort == .name {
        return filteredMembers.sorted {
          $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
      }

      guard room.role == .member else { return filteredMembers }
      let current = filteredMembers.first { $0.id == currentMemberID }
      let owner = filteredMembers.first { $0.isOwner && $0.id != currentMemberID }
      let remaining = filteredMembers.filter { $0.id != current?.id && $0.id != owner?.id }
      var prioritized: [ClassMember] = []
      if let current {
        prioritized.append(current)
      }
      if let owner {
        prioritized.append(owner)
      }
      return prioritized + remaining
    }

    public mutating func refreshLoadedViewState() {
      guard viewState == .loaded || viewState == .empty || viewState == .noSearchResults else { return }
      if members.isEmpty {
        viewState = .empty
      } else {
        viewState = visibleMembers.isEmpty ? .noSearchResults : .loaded
      }
    }
  }

  public enum Action: ViewAction, BindableAction {
    case binding(BindingAction<State>)
    case view(View)
    case filter(PresentationAction<ClassMemberFilterFeature.Action>)
    case editName(PresentationAction<ClassMemberEditNameFeature.Action>)
    case customAlert(PresentationAction<CustomAlertAction>)
    case loadingStarted(UUID)
    case membersLoaded(room: ClassRoom, members: [ClassMember], currentMemberID: Int, requestID: UUID)
    case loadFailed(requestID: UUID, message: String)
    case dataUpdated(room: ClassRoom, members: [ClassMember])
    case dataFailed(String)
    case delegate(DelegateAction)
  }

  public enum View {
    case backTapped
    case retryTapped
    case filterTapped
    case editNameTapped(Int)
    case nameSaved
    case removeTapped(Int)
    case removeConfirmed
  }

  public enum DelegateAction: Equatable {
    case dismiss
    case retryMembers(roomID: Int)
    case removeMember(roomID: Int, memberID: Int, currentMemberID: Int)
    case updateDisplayName(roomID: Int, memberID: Int, currentMemberID: Int, name: String)
  }

  public enum CancelID: Hashable, Sendable {
    case load(UUID)
  }

  public var body: some Reducer<State, Action> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .binding:
        state.refreshLoadedViewState()
        return .none
      case let .view(viewAction):
        return handleViewAction(state: &state, action: viewAction)
      case let .filter(filterAction):
        return handleFilterAction(state: &state, action: filterAction)
      case let .editName(editNameAction):
        return handleEditNameAction(state: &state, action: editNameAction)
      case let .customAlert(alertAction):
        return handleCustomAlertAction(state: &state, action: alertAction)
      case let .loadingStarted(requestID):
        state.activeLoadRequestID = requestID
        state.isLoading = true
        state.loadErrorMessage = nil
        if state.viewState == .loading || state.viewState == .error {
          state.viewState = .loading
        }
        return .none
      case let .membersLoaded(room, members, currentMemberID, requestID):
        guard state.activeLoadRequestID == requestID, state.room.id == room.id else { return .none }
        state.activeLoadRequestID = nil
        state.isLoading = false
        state.room = room
        state.members = members
        state.currentMemberID = currentMemberID
        state.viewState = .loaded
        state.refreshLoadedViewState()
        return .none
      case let .loadFailed(requestID, message):
        guard state.activeLoadRequestID == requestID else { return .none }
        state.activeLoadRequestID = nil
        state.isLoading = false
        state.loadErrorMessage = message
        if state.viewState == .loading {
          state.viewState = .error
        }
        return .none
      case let .dataUpdated(room, members):
        state.activeLoadRequestID = nil
        state.isLoading = false
        state.loadErrorMessage = nil
        state.room = room
        state.members = members
        state.viewState = .loaded
        state.refreshLoadedViewState()
        state.editName = nil
        state.pendingRemovalID = nil
        state.errorMessage = nil
        state.isSaving = false
        return .none
      case let .dataFailed(message):
        state.pendingRemovalID = nil
        state.editName = nil
        state.isSaving = false
        state.errorMessage = message
        state.customAlert = .alert(title: "요청을 완료하지 못했어요", message: message)
        return .none
      case .delegate:
        return .none
      }
    }
    .ifLet(\.$filter, action: \.filter) {
      ClassMemberFilterFeature()
    }
    .ifLet(\.$editName, action: \.editName) {
      ClassMemberEditNameFeature()
    }
    .ifLet(\.$customAlert, action: \.customAlert) {
      CustomConfirmAlert()
    }
  }
}

#if DEBUG
  public extension ClassMemberFeature.State {
    static func preview(room: ClassRoom) -> Self {
      Self(
        room: room,
        members: room.role == .owner
          ? MockClassRepository.figmaOwnerMembers
          : MockClassRepository.figmaParticipantMembers,
        currentMemberID: room.role == .owner ? 1 : 2,
        preloadedViewState: .loaded
      )
    }
  }
#endif

// MARK: - Action Handlers

extension ClassMemberFeature {
  private func handleFilterAction(
    state: inout State,
    action: PresentationAction<ClassMemberFilterFeature.Action>
  ) -> Effect<Action> {
    switch action {
    case .presented(.applyTapped):
      if let filter = state.filter {
        state.appliedFilter = filter
        state.hasAppliedSort = true
        state.refreshLoadedViewState()
      }
      state.filter = nil
      return .none
    case .presented(.dismissTapped), .dismiss:
      state.filter = nil
      return .none
    case .presented:
      return .none
    }
  }

  private func handleEditNameAction(
    state: inout State,
    action: PresentationAction<ClassMemberEditNameFeature.Action>
  ) -> Effect<Action> {
    switch action {
    case .presented(.dismissTapped), .dismiss:
      state.editName = nil
      return .none
    case .presented:
      return .none
    }
  }

  private func handleCustomAlertAction(
    state: inout State,
    action: PresentationAction<CustomAlertAction>
  ) -> Effect<Action> {
    switch action {
    case .presented(.confirmTapped):
      let isRemovalConfirmation = state.customAlert?.style == .deleteConfirm
      state.customAlert = nil
      state.errorMessage = nil
      return isRemovalConfirmation
        ? handleViewAction(state: &state, action: .removeConfirmed)
        : .none
    case .presented(.cancelTapped), .dismiss:
      state.customAlert = nil
      state.pendingRemovalID = nil
      state.errorMessage = nil
      return .none
    }
  }

  private func handleViewAction(
    state: inout State,
    action: View
  ) -> Effect<Action> {
    switch action {
    case .backTapped:
      state.activeLoadRequestID = nil
      state.isLoading = false
      return .merge(
        .cancel(id: CancelID.load(state.instanceID)),
        .send(.delegate(.dismiss))
      )
    case .retryTapped:
      guard !state.isLoading else { return .none }
      return .send(.delegate(.retryMembers(roomID: state.room.id)))
    case .filterTapped:
      state.filter = state.appliedFilter
      return .none
    case let .editNameTapped(id):
      guard id == state.currentMemberID, let member = state.members.first(where: { $0.id == id }) else { return .none }
      state.draftName = member.name
      state.editName = .init()
      return .none
    case .nameSaved:
      guard !state.isSaving,
            state.editName != nil,
            state.members.contains(where: { $0.id == state.currentMemberID })
      else { return .none }
      let name = state.draftName.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !name.isEmpty else { return .none }
      state.isSaving = true
      return .send(.delegate(.updateDisplayName(
        roomID: state.room.id,
        memberID: state.currentMemberID,
        currentMemberID: state.currentMemberID,
        name: name
      )))
    case let .removeTapped(id):
      guard state.room.role == .owner,
            id != state.currentMemberID,
            let member = state.members.first(where: { $0.id == id }),
            !member.isOwner
      else { return .none }
      state.pendingRemovalID = id
      state.customAlert = CustomAlertState(
        title: "\(member.name)님을 클래스에서 내보낼까요?\n한 번 내보내면 되돌릴 수 없어요.",
        confirmTitle: "내보내기",
        cancelTitle: "뒤로가기",
        isDestructive: true,
        style: .deleteConfirm
      )
      return .none
    case .removeConfirmed:
      guard !state.isSaving,
            state.room.role == .owner,
            let id = state.pendingRemovalID,
            id != state.currentMemberID,
            let member = state.members.first(where: { $0.id == id }),
            !member.isOwner
      else { return .none }
      state.pendingRemovalID = nil
      state.isSaving = true
      return .send(.delegate(.removeMember(
        roomID: state.room.id,
        memberID: id,
        currentMemberID: state.currentMemberID
      )))
    }
  }
}

@Reducer
public struct ClassMemberEditNameFeature {
  @ObservableState
  public struct State: Equatable {
    public init() {}
  }

  public enum Action {
    case dismissTapped
  }

  public init() {}

  public var body: some Reducer<State, Action> {
    EmptyReducer()
  }
}

@Reducer
public struct ClassMemberFilterFeature {
  @ObservableState
  public struct State: Equatable {
    public var participation: ClassMemberParticipation = .all
    public var completion: ClassMemberCompletion = .all
    public var attendance: ClassMemberAttendance = .all
    public var sort: ClassMemberSort = .name

    public init() {}
  }

  public enum Action: Equatable {
    case participationSelected(ClassMemberParticipation)
    case completionSelected(ClassMemberCompletion)
    case attendanceSelected(ClassMemberAttendance)
    case sortSelected(ClassMemberSort)
    case applyTapped
    case dismissTapped
  }

  public init() {}

  public var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case let .participationSelected(value):
        guard value == .all else { return .none }
        state.participation = value
      case let .completionSelected(value):
        guard value == .all else { return .none }
        state.completion = value
      case let .attendanceSelected(value):
        guard value == .all else { return .none }
        state.attendance = value
      case let .sortSelected(value):
        guard value == .name else { return .none }
        state.sort = value
      case .applyTapped, .dismissTapped:
        break
      }
      return .none
    }
  }
}
