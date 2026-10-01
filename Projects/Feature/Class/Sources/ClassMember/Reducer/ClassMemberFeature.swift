import ClassDomainInterface
import ComposableArchitecture
import Foundation
import PickeSharedUI

@Reducer
public struct ClassMemberFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public struct Member: Equatable, Identifiable {
      public let id: Int
      public let name: String
      public let isOwner: Bool

      public init(id: Int, name: String, isOwner: Bool = false) {
        self.id = id
        self.name = name
        self.isOwner = isOwner
      }
    }

    public let room: ClassRoom
    public var members: [Member]
    public var searchText = ""
    public var selectedMember: Member?
    public var appliedFilter = ClassMemberFilterFeature.State()
    @Presents public var filter: ClassMemberFilterFeature.State?
    @Presents public var customAlert: CustomAlertState<CustomAlertAction>?

    public init(room: ClassRoom) {
      self.room = room
      members = [Member(id: 1, name: "선생님", isOwner: true)]
        + (0 ..< max(0, room.memberCount - 1)).map { index in
          Member(id: index + 2, name: "학생 \(index + 1)")
        }
    }

    public var visibleMembers: [Member] {
      let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
      return query.isEmpty ? members : members.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }
  }

  public enum Action: ViewAction, BindableAction {
    case binding(BindingAction<State>)
    case view(View)
    case filter(PresentationAction<ClassMemberFilterFeature.Action>)
    case customAlert(PresentationAction<CustomAlertAction>)
    case delegate(DelegateAction)
  }

  public enum View {
    case backTapped
    case filterTapped
    case removeTapped(Int)
    case removeConfirmed
    case removeCancelled
  }

  public enum DelegateAction: Equatable {
    case dismiss
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
        }
        state.filter = nil
        return .none
      case .filter(.presented(.dismissTapped)), .filter(.dismiss):
        state.filter = nil
        return .none
      case .filter:
        return .none
      case let .customAlert(alertAction):
        switch alertAction {
        case .presented(.confirmTapped):
          guard let member = state.selectedMember else { return .none }
          state.members.removeAll(where: { $0.id == member.id })
          state.selectedMember = nil
          state.customAlert = nil
          return .none
        case .presented(.cancelTapped), .dismiss:
          state.selectedMember = nil
          state.customAlert = nil
          return .none
        }
      case .delegate:
        return .none
      }
    }
    .ifLet(\.$filter, action: \.filter) {
      ClassMemberFilterFeature()
    }
    .ifLet(\.$customAlert, action: \.customAlert) {
      CustomConfirmAlert()
    }
  }
}

extension ClassMemberFeature {
  private func handleViewAction(state: inout State, action: View) -> Effect<Action> {
    switch action {
    case .backTapped:
      return .send(.delegate(.dismiss))
    case .filterTapped:
      state.filter = state.appliedFilter
      return .none
    case let .removeTapped(id):
      guard state.room.role == .owner,
            let member = state.members.first(where: { $0.id == id && !$0.isOwner })
      else { return .none }
      state.selectedMember = member
      state.customAlert = CustomAlertState(
        title: "\(member.name)님을 클래스에서 내보낼까요?\n한 번 내보내면 되돌릴 수 없어요.",
        confirmTitle: "내보내기",
        cancelTitle: "뒤로가기",
        isDestructive: true,
        style: .deleteConfirm
      )
      return .none
    case .removeConfirmed:
      guard let member = state.selectedMember else { return .none }
      state.members.removeAll(where: { $0.id == member.id })
      state.selectedMember = nil
      state.customAlert = nil
      return .none
    case .removeCancelled:
      state.selectedMember = nil
      state.customAlert = nil
      return .none
    }
  }
}

@Reducer
public struct ClassMemberFilterFeature {
  @ObservableState
  public struct State: Equatable {
    public var participation: Participation = .all
    public var completion: Completion = .all
    public var attendance: Attendance = .all
    public var sort: Sort = .name

    public init() {}
  }

  public enum Action: Equatable {
    case participationSelected(Participation)
    case completionSelected(Completion)
    case attendanceSelected(Attendance)
    case sortSelected(Sort)
    case applyTapped
    case dismissTapped
  }

  public enum Participation: String, CaseIterable, Equatable {
    case all = "전체"
    case notParticipated = "미참여 4"
    case completed = "참여 완료 18"
    case inProgress = "진행 중 10"
  }

  public enum Completion: String, CaseIterable, Equatable {
    case all = "전체"
    case noComment = "댓글 미작성"
    case noAfterVote = "사후 투표 미완료"
    case inProgress = "진행 중 10"
  }

  public enum Attendance: String, CaseIterable, Equatable {
    case all = "전체"
    case changed = "입장 변화"
    case unchanged = "입장 유지"
    case inProgress = "진행 중 10"
  }

  public enum Sort: String, CaseIterable, Equatable {
    case name = "이름순"
    case comments = "댓글 많은순"
    case replies = "대댓글 많은순"
    case recommendations = "추천순"
  }

  public init() {}

  public var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case let .participationSelected(value):
        state.participation = value
      case let .completionSelected(value):
        state.completion = value
      case let .attendanceSelected(value):
        state.attendance = value
      case let .sortSelected(value):
        state.sort = value
      case .applyTapped, .dismissTapped:
        break
      }
      return .none
    }
  }
}
