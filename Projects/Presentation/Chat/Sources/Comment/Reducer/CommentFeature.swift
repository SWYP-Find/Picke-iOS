//
//  CommentFeature.swift
//  Chat
//
//  댓글 화면 mock 상태. 서버 API 가 붙기 전까지 화면/상호작용 형태를 고정한다.
//

import Foundation

import ComposableArchitecture

@Reducer
public struct CommentFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public var battleId: Int
    public var title: String
    public var voteSummary: VoteSummary
    public var selectedFilter: CommentFilter = .all
    public var selectedSort: CommentSort = .popular
    public var comments: [CommentItem]
    public var commentText: String = ""

    public var filteredComments: [CommentItem] {
      switch selectedFilter {
      case .all:
        comments
      case .optionA:
        comments.filter { $0.option == .a }
      case .optionB:
        comments.filter { $0.option == .b }
      }
    }

    public var isSendEnabled: Bool {
      !commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    public init(
      battleId: Int = 0,
      title: String = "원가 18만 원 명품은 사기다",
      voteSummary: VoteSummary = .mock,
      comments: [CommentItem] = CommentItem.mocks
    ) {
      self.battleId = battleId
      self.title = title
      self.voteSummary = voteSummary
      self.comments = comments
    }
  }

  public enum Action: ViewAction, BindableAction {
    case binding(BindingAction<State>)
    case view(View)
    case delegate(DelegateAction)
  }

  @CasePathable
  public enum View {
    case backButtonTapped
    case shareTapped
    case filterTapped(CommentFilter)
    case sortTapped(CommentSort)
    case moreTapped(UUID)
    case replyTapped(UUID)
    case likeTapped(UUID)
    case sendTapped
  }

  public enum DelegateAction: Equatable {
    case dismiss
  }

  public var body: some Reducer<State, Action> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .binding(\.commentText):
        if state.commentText.count > 200 {
          state.commentText = String(state.commentText.prefix(200))
        }
        return .none

      case .binding:
        return .none

      case let .view(viewAction):
        return handleViewAction(state: &state, action: viewAction)

      case .delegate:
        return .none
      }
    }
  }
}

extension CommentFeature {
  private func handleViewAction(
    state: inout State,
    action: View
  ) -> Effect<Action> {
    switch action {
    case .backButtonTapped:
      return .send(.delegate(.dismiss))

    case .shareTapped, .moreTapped, .replyTapped:
      return .none

    case let .filterTapped(filter):
      state.selectedFilter = filter
      return .none

    case let .sortTapped(sort):
      state.selectedSort = sort
      switch sort {
      case .popular:
        state.comments.sort { $0.likeCount > $1.likeCount }
      case .latest:
        state.comments.sort { $0.createdOrder > $1.createdOrder }
      }
      return .none

    case let .likeTapped(id):
      guard let index = state.comments.firstIndex(where: { $0.id == id }) else { return .none }
      state.comments[index].isLiked.toggle()
      state.comments[index].likeCount += state.comments[index].isLiked ? 1 : -1
      return .none

    case .sendTapped:
      let text = state.commentText.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !text.isEmpty else { return .none }
      state.comments.insert(
        CommentItem(
          author: "나",
          timeAgo: "방금 전",
          option: .a,
          content: text,
          replyCount: 0,
          likeCount: 0,
          createdOrder: (state.comments.map(\.createdOrder).max() ?? 0) + 1
        ),
        at: 0
      )
      state.commentText = ""
      return .none
    }
  }
}

public enum CommentFilter: String, CaseIterable, Equatable {
  case all
  case optionA
  case optionB

  public var title: String {
    switch self {
    case .all: "전체"
    case .optionA: "A"
    case .optionB: "B"
    }
  }
}

public enum CommentSort: String, CaseIterable, Equatable {
  case popular
  case latest

  public var title: String {
    switch self {
    case .popular: "인기순"
    case .latest: "최신순"
    }
  }
}

public struct VoteSummary: Equatable {
  public var changeBadgeTitle: String
  public var optionA: VoteOptionSummary
  public var optionB: VoteOptionSummary

  public init(
    changeBadgeTitle: String,
    optionA: VoteOptionSummary,
    optionB: VoteOptionSummary
  ) {
    self.changeBadgeTitle = changeBadgeTitle
    self.optionA = optionA
    self.optionB = optionB
  }

  public static let mock = VoteSummary(
    changeBadgeTitle: "생각이 바뀌었어요",
    optionA: .init(label: "A", title: "변기는 변기다", representative: "플라톤", percentage: 0.595),
    optionB: .init(label: "B", title: "예술이다", representative: "사르트르", percentage: 0.405)
  )
}

public struct VoteOptionSummary: Equatable {
  public var label: String
  public var title: String
  public var representative: String
  public var percentage: Double

  public init(
    label: String,
    title: String,
    representative: String,
    percentage: Double
  ) {
    self.label = label
    self.title = title
    self.representative = representative
    self.percentage = percentage
  }
}

public enum CommentOption: Equatable {
  case a
  case b

  public var label: String {
    switch self {
    case .a: "A"
    case .b: "B"
    }
  }
}

public struct CommentItem: Equatable, Identifiable {
  public let id: UUID
  public var author: String
  public var timeAgo: String
  public var option: CommentOption
  public var content: String
  public var replyCount: Int
  public var likeCount: Int
  public var isLiked: Bool
  public var createdOrder: Int

  public init(
    id: UUID = UUID(),
    author: String,
    timeAgo: String,
    option: CommentOption,
    content: String,
    replyCount: Int,
    likeCount: Int,
    isLiked: Bool = false,
    createdOrder: Int
  ) {
    self.id = id
    self.author = author
    self.timeAgo = timeAgo
    self.option = option
    self.content = content
    self.replyCount = replyCount
    self.likeCount = likeCount
    self.isLiked = isLiked
    self.createdOrder = createdOrder
  }

  public static let mocks: [CommentItem] = [
    .init(
      id: UUID(uuidString: "00000000-0000-0000-0000-000000000001") ?? UUID(),
      author: "사유하는 사용자",
      timeAgo: "2분 전",
      option: .a,
      content: "제도화가 무서운 건, 사회적 압력이 '선택'을 '의무'로 바꿀 수 있다는 거예요. 네덜란드 사례를 보면 우려가 현실이 되고 있죠. 제도화가 무서운 건, 사회적 압력이 '선택'을 '의무'로 바꿀 수 있다는 거예요.",
      replyCount: 23,
      likeCount: 1340,
      createdOrder: 3
    ),
    .init(
      id: UUID(uuidString: "00000000-0000-0000-0000-000000000002") ?? UUID(),
      author: "논쟁을 즐기는 사람",
      timeAgo: "8분 전",
      option: .b,
      content: "맥락을 바꾸면 같은 사물도 전혀 다른 의미를 갖게 됩니다. 결국 예술은 물건의 가격보다 해석의 층위로 결정되는 것 같아요.",
      replyCount: 8,
      likeCount: 692,
      createdOrder: 2
    ),
    .init(
      id: UUID(uuidString: "00000000-0000-0000-0000-000000000003") ?? UUID(),
      author: "깊게 읽는 독자",
      timeAgo: "15분 전",
      option: .a,
      content: "브랜드가 붙었다고 본질이 달라지는 건 아니라고 봅니다. 사용되는 기능과 재료가 같다면 사치재의 권위는 결국 합의된 환상에 가깝죠.",
      replyCount: 4,
      likeCount: 421,
      createdOrder: 1
    ),
  ]
}
