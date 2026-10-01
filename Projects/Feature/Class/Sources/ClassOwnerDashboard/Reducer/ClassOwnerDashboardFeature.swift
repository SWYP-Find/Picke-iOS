import ClassDomainInterface
import ComposableArchitecture
import Foundation

@Reducer
public struct ClassOwnerDashboardFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public let room: ClassRoom
    public var selectedTab: ClassOwnerTab = .home
    public var opinionFilter: ClassOwnerOpinionFilter = .all
    public var memberSort: ClassOwnerMemberSort = .name
    public var searchText = ""
    public var members: [ClassOwnerMember]
    public var opinions: [ClassOwnerOpinion]

    public init(room: ClassRoom) {
      self.room = room
      members = [
        ClassOwnerMember(id: 1, name: "김민지", participationCount: 8, needsReview: true),
        ClassOwnerMember(id: 2, name: "이서준", participationCount: 7),
        ClassOwnerMember(id: 3, name: "박지우", participationCount: 6),
        ClassOwnerMember(id: 4, name: "최유진", participationCount: 5),
        ClassOwnerMember(id: 5, name: "정다은", participationCount: 4),
        ClassOwnerMember(id: 6, name: "한도윤", participationCount: 3, needsReview: true),
      ]
      opinions = [
        ClassOwnerOpinion(
          id: 1,
          author: "김민지",
          text: "피해자 보호를 위한 기준도 함께 필요하지 않을까요?",
          replyCount: 23
        ),
        ClassOwnerOpinion(
          id: 2,
          author: "이서준",
          text: "제도화가 선택을 의무로 바꾸지 않도록 기준이 필요해요.",
          replyCount: 12
        ),
        ClassOwnerOpinion(
          id: 3,
          author: "박지우",
          text: "교육과 보호도 함께 고려해야 한다고 생각합니다.",
          replyCount: 4
        ),
      ]
    }

    public var visibleMembers: [ClassOwnerMember] {
      let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
      let matching = query.isEmpty ? members : members.filter { $0.name.localizedCaseInsensitiveContains(query) }
      switch memberSort {
      case .name:
        return matching.sorted { $0.name < $1.name }
      case .participation:
        return matching.sorted { $0.participationCount > $1.participationCount }
      case .needsReview:
        return matching.sorted { $0.needsReview && !$1.needsReview }
      }
    }

    public var visibleOpinions: [ClassOwnerOpinion] {
      switch opinionFilter {
      case .all, .inProgress:
        return opinions
      case .recommended:
        return opinions.sorted { $0.replyCount > $1.replyCount }
      case .replies:
        return opinions.sorted { $0.replyCount > $1.replyCount }
      }
    }
  }

  public enum Action: ViewAction {
    case view(View)
    case delegate(DelegateAction)
  }

  public enum View: Equatable {
    case backTapped
    case tabSelected(ClassOwnerTab)
    case opinionFilterSelected(ClassOwnerOpinionFilter)
    case memberSortSelected(ClassOwnerMemberSort)
    case searchTextChanged(String)
    case memberTapped(Int)
    case opinionTapped(Int)
    case feedbackTapped(Int)
  }

  public enum DelegateAction: Equatable {
    case dismiss
    case openMemberDetail(ClassOwnerMember)
    case openReplyDetail(ClassOwnerOpinion)
    case openFeedback(ClassOwnerMember)
  }

  public var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case let .view(viewAction):
        switch viewAction {
        case .backTapped:
          return .send(.delegate(.dismiss))
        case let .tabSelected(tab):
          state.selectedTab = tab
        case let .opinionFilterSelected(filter):
          state.opinionFilter = filter
        case let .memberSortSelected(sort):
          state.memberSort = sort
        case let .searchTextChanged(text):
          state.searchText = text
        case let .memberTapped(id):
          guard let member = state.members.first(where: { $0.id == id }) else { return .none }
          return .send(.delegate(.openMemberDetail(member)))
        case let .opinionTapped(id):
          guard let opinion = state.opinions.first(where: { $0.id == id }) else { return .none }
          return .send(.delegate(.openReplyDetail(opinion)))
        case let .feedbackTapped(id):
          guard let member = state.members.first(where: { $0.id == id }) else { return .none }
          return .send(.delegate(.openFeedback(member)))
        }
        return .none
      case .delegate:
        return .none
      }
    }
  }
}
