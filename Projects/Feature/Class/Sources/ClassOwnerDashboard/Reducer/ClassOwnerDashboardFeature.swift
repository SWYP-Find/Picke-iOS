import ClassDomainInterface
import ComposableArchitecture
import Foundation

@Reducer
public struct ClassOwnerDashboardFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public struct PreviewMetrics: Equatable {
      public let commentAuthorCount: Int
      public let optionAVoteCount: Int
      public let optionBVoteCount: Int

      public init(commentAuthorCount: Int, optionAVoteCount: Int, optionBVoteCount: Int) {
        self.commentAuthorCount = commentAuthorCount
        self.optionAVoteCount = optionAVoteCount
        self.optionBVoteCount = optionBVoteCount
      }
    }

    public enum MemberViewState: Equatable {
      case unavailable
      case noSearchResults
      case loaded([ClassOwnerMember])
    }

    public enum OpinionViewState: Equatable {
      case empty
      case loaded([ClassOwnerOpinion])
    }

    public enum TopOpinionViewState: Equatable {
      case empty
      case unavailable
      case loaded([ClassOwnerOpinion])
    }

    public enum MemberSummaryState: Equatable {
      case unavailable
      case empty
      case loaded([ClassOwnerMember])
    }

    public let room: ClassRoom
    public var selectedTab: ClassOwnerTab = .home
    public var opinionFilter: ClassOwnerOpinionFilter = .popular
    public var memberSort: ClassOwnerMemberSort = .name
    public var memberFilter: MemberFilter = .all
    public var searchText = ""
    public var members: [ClassOwnerMember] = []
    public var opinions: [ClassOwnerOpinion] = []
    #if DEBUG
      public var usesPreviewContent = false
      public var previewMetrics: PreviewMetrics?
    #endif

    public init(room: ClassRoom) {
      self.room = room
    }

    #if DEBUG
      public static func preview(room: ClassRoom, tab: ClassOwnerTab = .home) -> Self {
        var state = Self(room: room)
        state.selectedTab = tab
        state.usesPreviewContent = true
        state.previewMetrics = PreviewMetrics(commentAuthorCount: 24, optionAVoteCount: 18, optionBVoteCount: 10)
        state.members = [
          ClassOwnerMember(id: 1, name: "김민지", participationCount: 8, needsReview: true),
          ClassOwnerMember(id: 2, name: "이서준", participationCount: 7),
          ClassOwnerMember(id: 3, name: "박지우", participationCount: 6),
          ClassOwnerMember(id: 4, name: "최유진", participationCount: 0),
          ClassOwnerMember(id: 5, name: "정다은", participationCount: 0),
          ClassOwnerMember(id: 6, name: "한도윤", participationCount: 0, needsReview: true),
        ]
        state.members += (7 ... 32).map { id in
          ClassOwnerMember(id: id, name: "희망 \(id)", participationCount: id < 32 ? 1 : 0)
        }
        state.opinions = [
          ClassOwnerOpinion(
            id: 1,
            author: "김민지",
            text: "피해자 보호를 위한 기준도 함께 필요하지 않을까요?",
            replyCount: 23,
            recommendationCount: 1340,
            createdAt: Date(timeIntervalSince1970: 1_780_000_300)
          ),
          ClassOwnerOpinion(
            id: 2,
            author: "이서준",
            text: "제도화가 선택을 의무로 바꾸지 않도록 기준이 필요해요.",
            replyCount: 12,
            recommendationCount: 840,
            createdAt: Date(timeIntervalSince1970: 1_780_000_200)
          ),
          ClassOwnerOpinion(
            id: 3,
            author: "박지우",
            text: "교육과 보호도 함께 고려해야 한다고 생각합니다.",
            replyCount: 4,
            recommendationCount: 510,
            createdAt: Date(timeIntervalSince1970: 1_780_000_100)
          ),
        ]
        return state
      }
    #endif

    public var searchedMembers: [ClassOwnerMember] {
      let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
      return query.isEmpty ? members : members.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    public var visibleMembers: [ClassOwnerMember] {
      let searched = searchedMembers
      let matching: [ClassOwnerMember] = switch memberFilter {
      case .all: searched
      case .participated: searched.filter { $0.participationCount > 0 }
      case .notParticipated: searched.filter { $0.participationCount == 0 }
      }
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
      guard let activeOpinionFilter else { return opinions }
      switch activeOpinionFilter {
      case .latest:
        return opinions.sorted { ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast) }
      case .popular:
        return opinions.sorted { ($0.recommendationCount ?? 0) > ($1.recommendationCount ?? 0) }
      }
    }

    public var activeOpinionFilter: ClassOwnerOpinionFilter? {
      canSortOpinions(opinionFilter) ? opinionFilter : nil
    }

    public var topOpinionViewState: TopOpinionViewState {
      guard !opinions.isEmpty else { return .empty }
      guard canSortOpinions(.popular) else { return .unavailable }
      let top = Array(opinions.sorted { ($0.recommendationCount ?? 0) > ($1.recommendationCount ?? 0) }.prefix(2))
      return .loaded(top)
    }

    public var memberViewState: MemberViewState {
      guard !members.isEmpty else { return .unavailable }
      let visible = visibleMembers
      return visible.isEmpty ? .noSearchResults : .loaded(visible)
    }

    public var needsReviewViewState: MemberSummaryState {
      guard !members.isEmpty else { return .unavailable }
      let matching = members.filter(\.needsReview)
      return matching.isEmpty ? .empty : .loaded(matching)
    }

    public var highParticipationViewState: MemberSummaryState {
      guard !members.isEmpty else { return .unavailable }
      let matching = Array(members.filter { $0.participationCount > 0 }
        .sorted { $0.participationCount > $1.participationCount }
        .prefix(3))
      return matching.isEmpty ? .empty : .loaded(matching)
    }

    public var opinionViewState: OpinionViewState {
      let visible = visibleOpinions
      return visible.isEmpty ? .empty : .loaded(visible)
    }

    public func canSortOpinions(_ filter: ClassOwnerOpinionFilter) -> Bool {
      guard !opinions.isEmpty else { return false }
      switch filter {
      case .popular: return opinions.allSatisfy { $0.recommendationCount != nil }
      case .latest: return opinions.allSatisfy { $0.createdAt != nil }
      }
    }

    public var availableOpinionFilters: Set<ClassOwnerOpinionFilter> {
      Set(ClassOwnerOpinionFilter.allCases.filter(canSortOpinions))
    }
  }

  public enum MemberFilter: CaseIterable, Hashable, Sendable {
    case all
    case participated
    case notParticipated
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
    case memberFilterSelected(MemberFilter)
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
          guard state.canSortOpinions(filter) else { return .none }
          state.opinionFilter = filter
        case let .memberSortSelected(sort):
          state.memberSort = sort
        case let .memberFilterSelected(filter):
          guard !state.members.isEmpty || filter == .all else { return .none }
          state.memberFilter = filter
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
