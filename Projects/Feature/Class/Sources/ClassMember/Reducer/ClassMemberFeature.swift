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
      case unavailable
      case noSearchResults
      case members([ClassMember])
    }

    public var room: ClassRoom
    public var members: [ClassMember]
    public var currentMemberID: Int
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

    public init(room: ClassRoom, members: [ClassMember] = [], currentMemberID: Int = 1) {
      self.room = room
      self.members = members
      self.currentMemberID = currentMemberID
    }

    public var visibleMembers: [ClassMember] {
      let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
      let filteredMembers = query.isEmpty
        ? members
        : members.filter { $0.name.localizedCaseInsensitiveContains(query) }

      guard hasAppliedSort else { return filteredMembers }
      switch appliedFilter.sort {
      case .name:
        return filteredMembers.sorted {
          $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
      case .comments, .replies, .recommendations:
        return filteredMembers
      }
    }

    public var viewState: ViewState {
      guard !members.isEmpty else { return .unavailable }
      let visible = visibleMembers
      return visible.isEmpty ? .noSearchResults : .members(visible)
    }
  }

  public enum Action: ViewAction, BindableAction {
    case binding(BindingAction<State>)
    case view(View)
    case filter(PresentationAction<ClassMemberFilterFeature.Action>)
    case editName(PresentationAction<ClassMemberEditNameFeature.Action>)
    case customAlert(PresentationAction<CustomAlertAction>)
    case membersLoaded(room: ClassRoom, members: [ClassMember], currentMemberID: Int)
    case dataUpdated(room: ClassRoom, members: [ClassMember])
    case dataFailed(String)
    case delegate(DelegateAction)
  }

  public enum View {
    case backTapped
    case filterTapped
    case editNameTapped(Int)
    case nameSaved
    case removeTapped(Int)
    case removeConfirmed
  }

  public enum DelegateAction: Equatable {
    case dismiss
    case removeMember(roomID: Int, memberID: Int, currentMemberID: Int)
    case updateDisplayName(roomID: Int, memberID: Int, currentMemberID: Int, name: String)
  }

  public var body: some Reducer<State, Action> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .binding:
        return .none
      case let .view(viewAction):
        return handleViewAction(state: &state, action: viewAction)
      case .filter(.presented(.applyTapped)):
        if let filter = state.filter {
          state.appliedFilter = filter
          state.hasAppliedSort = true
        }
        state.filter = nil
        return .none
      case .filter(.presented(.dismissTapped)), .filter(.dismiss):
        state.filter = nil
        return .none
      case .filter:
        return .none
      case .editName(.presented(.dismissTapped)), .editName(.dismiss):
        state.editName = nil
        return .none
      case .editName:
        return .none
      case .customAlert(.presented(.confirmTapped)):
        let isRemovalConfirmation = state.customAlert?.style == .deleteConfirm
        state.customAlert = nil
        state.errorMessage = nil
        return isRemovalConfirmation
          ? handleViewAction(state: &state, action: .removeConfirmed)
          : .none
      case .customAlert(.presented(.cancelTapped)), .customAlert(.dismiss):
        state.customAlert = nil
        state.pendingRemovalID = nil
        state.errorMessage = nil
        return .none
      case let .membersLoaded(room, members, currentMemberID):
        state.room = room
        state.members = members
        state.currentMemberID = currentMemberID
        return .none
      case let .dataUpdated(room, members):
        state.room = room
        state.members = members
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
        members: [
          ClassMember(id: 1, name: "김선생", isOwner: true),
          ClassMember(id: 2, name: "공은지"),
          ClassMember(id: 3, name: "권동현"),
          ClassMember(id: 4, name: "김민지"),
          ClassMember(id: 5, name: "천다올"),
          ClassMember(id: 6, name: "유시영"),
          ClassMember(id: 7, name: "주천수"),
          ClassMember(id: 8, name: "김예은"),
          ClassMember(id: 9, name: "서원지"),
          ClassMember(id: 10, name: "현준혁"),
        ]
      )
    }
  }
#endif

extension ClassMemberFeature {
  private func handleViewAction(state: inout State, action: View) -> Effect<Action> {
    switch action {
    case .backTapped:
      return .send(.delegate(.dismiss))
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
