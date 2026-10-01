import ClassDomainInterface
import ComposableArchitecture
import Foundation

@Reducer
public struct ClassOwnerDashboardFeature {
  public init() {}

  public enum Tab: String, CaseIterable, Hashable {
    case home = "홈"
    case members = "멤버"
    case opinions = "의견"
  }

  public enum OpinionFilter: String, CaseIterable, Hashable {
    case all = "전체"
    case recommended = "추천순"
    case replies = "대댓글 많은순"
    case inProgress = "진행 중 10"
  }

  public enum MemberSort: String, CaseIterable, Hashable {
    case name = "이름순"
    case participation = "참여 많은순"
    case needsReview = "확인 필요순"
  }

  public struct Member: Equatable, Identifiable, Sendable {
    public let id: Int
    public let name: String
    public let participationCount: Int
    public let needsReview: Bool

    public init(id: Int, name: String, participationCount: Int, needsReview: Bool = false) {
      self.id = id
      self.name = name
      self.participationCount = participationCount
      self.needsReview = needsReview
    }
  }

  public struct Opinion: Equatable, Identifiable, Sendable {
    public let id: Int
    public let author: String
    public let text: String
    public let replyCount: Int
    public let isReported: Bool

    public init(
      id: Int,
      author: String,
      text: String,
      replyCount: Int,
      isReported: Bool = false
    ) {
      self.id = id
      self.author = author
      self.text = text
      self.replyCount = replyCount
      self.isReported = isReported
    }
  }

  @ObservableState
  public struct State: Equatable {
    public let room: ClassRoom
    public var selectedTab: Tab = .home
    public var opinionFilter: OpinionFilter = .all
    public var memberSort: MemberSort = .name
    public var searchText = ""
    public var members: [Member]
    public var opinions: [Opinion]

    public init(room: ClassRoom) {
      self.room = room
      members = [
        Member(id: 1, name: "김민지", participationCount: 8, needsReview: true),
        Member(id: 2, name: "이서준", participationCount: 7),
        Member(id: 3, name: "박지우", participationCount: 6),
        Member(id: 4, name: "최유진", participationCount: 5),
        Member(id: 5, name: "정다은", participationCount: 4),
        Member(id: 6, name: "한도윤", participationCount: 3, needsReview: true),
      ]
      opinions = [
        Opinion(
          id: 1,
          author: "김민지",
          text: "피해자 보호를 위한 기준도 함께 필요하지 않을까요?",
          replyCount: 23
        ),
        Opinion(
          id: 2,
          author: "이서준",
          text: "제도화가 선택을 의무로 바꾸지 않도록 기준이 필요해요.",
          replyCount: 12
        ),
        Opinion(
          id: 3,
          author: "박지우",
          text: "교육과 보호도 함께 고려해야 한다고 생각합니다.",
          replyCount: 4
        ),
      ]
    }

    public var visibleMembers: [Member] {
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

    public var visibleOpinions: [Opinion] {
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
    case tabSelected(Tab)
    case opinionFilterSelected(OpinionFilter)
    case memberSortSelected(MemberSort)
    case searchTextChanged(String)
    case memberTapped(Int)
    case opinionTapped(Int)
    case feedbackTapped(Int)
  }

  public enum DelegateAction: Equatable {
    case dismiss
    case openMemberDetail(Member)
    case openReplyDetail(Opinion)
    case openFeedback(Member)
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
