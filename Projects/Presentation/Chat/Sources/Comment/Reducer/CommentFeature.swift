//
//  CommentFeature.swift
//  Chat
//
//  댓글 화면. vote-stats API 로 상단 통계만 실데이터 사용,
//  댓글 리스트는 아직 mock.
//

import Foundation

import ComposableArchitecture
import DesignSystem
import DomainInterface
import Entity
import LogMacro

@Reducer
public struct CommentFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public var battleId: Int
    public var perspectiveId: Int?
    public var title: String
    public var voteSummary: VoteSummary
    public var isLoadingStats: Bool = false
    public var isLoadingComments: Bool = false
    public var isSubmitting: Bool = false
    public var nextCursor: String?
    public var hasNext: Bool = false
    public var selectedFilter: CommentFilter = .all
    public var selectedSort: CommentSort = .popular
    public var reportTargetCommentID: UUID?
    @Presents public var customAlert: CustomAlertState<CustomAlertAction>?
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
        && !isSubmitting
        && perspectiveId != nil
    }

    public init(
      battleId: Int = 0,
      perspectiveId: Int? = nil,
      title: String = "",
      voteSummary: VoteSummary = .mock,
      comments: [CommentItem] = []
    ) {
      self.battleId = battleId
      self.perspectiveId = perspectiveId
      self.title = title
      self.voteSummary = voteSummary
      self.comments = comments
    }
  }

  public enum Action: ViewAction, BindableAction {
    case binding(BindingAction<State>)
    case view(View)
    case async(AsyncAction)
    case inner(InnerAction)
    case scope(ScopeAction)
    case delegate(DelegateAction)
  }

  @CasePathable
  public enum View {
    case onAppear
    case backButtonTapped
    case shareTapped
    case filterTapped(CommentFilter)
    case sortTapped(CommentSort)
    case moreTapped(UUID)
    case replyTapped(UUID)
    case reportButtonTapped(UUID)
    case reportConfirmTapped(UUID)
    case reportPopupDismissed
    case likeTapped(UUID)
    case sendTapped
  }

  public enum AsyncAction: Equatable {
    case fetchBattle
    case fetchVoteStats
    case fetchPerspectives(reset: Bool)
    case toggleLike(commentId: Int, currentlyLiked: Bool)
    case createComment(perspectiveId: Int, content: String)
  }

  public enum InnerAction: Equatable {
    case battleResponse(Result<BattleDetail, BattleError>)
    case voteStatsResponse(Result<BattleVoteStats, BattleError>)
    case perspectivesResponse(Result<BattlePerspectivePage, BattleError>, reset: Bool)
    case likeResponse(Result<CommentLikeResult, CommentError>)
    case createCommentResponse(Result<PerspectiveCommentMutationResult, CommentError>)
  }

  @CasePathable
  public enum ScopeAction: Equatable {
    case customAlert(PresentationAction<CustomAlertAction>)
  }

  public enum DelegateAction: Equatable {
    case dismiss
    case openReply(CommentItem)
  }

  nonisolated enum CancelID: Hashable {
    case fetchBattle
    case fetchVoteStats
    case fetchPerspectives
    case toggleLike
    case createComment
  }

  @Dependency(\.battleRepository) private var battleRepository
  @Dependency(\.commentRepository) private var commentRepository
  @Dependency(\.perspectiveRepository) private var perspectiveRepository

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

      case let .async(asyncAction):
        return handleAsyncAction(state: &state, action: asyncAction)

      case let .inner(innerAction):
        return handleInnerAction(state: &state, action: innerAction)

      case let .scope(scopeAction):
        return handleScopeAction(state: &state, action: scopeAction)

      case .delegate:
        return .none
      }
    }
    .ifLet(\.$customAlert, action: \.scope.customAlert) {
      CustomConfirmAlert()
    }
  }
}

extension CommentFeature {
  private func handleViewAction(
    state: inout State,
    action: View
  ) -> Effect<Action> {
    switch action {
    case .onAppear:
      return .merge(
        .send(.async(.fetchBattle)),
        .send(.async(.fetchVoteStats)),
        .send(.async(.fetchPerspectives(reset: true)))
      )

    case .backButtonTapped:
      return .send(.delegate(.dismiss))

    case .shareTapped:
      return .none

    case let .moreTapped(id), let .replyTapped(id):
      guard let comment = state.comments.first(where: { $0.id == id }) else { return .none }
      state.reportTargetCommentID = nil
      return .send(.delegate(.openReply(comment)))

    case let .reportButtonTapped(id):
      state.reportTargetCommentID = id
      state.customAlert = .report()
      return .none

    case .reportPopupDismissed:
      state.reportTargetCommentID = nil
      state.customAlert = nil
      return .none

    case let .reportConfirmTapped(id):
      state.reportTargetCommentID = nil
      Log.debug("[CommentFeature] report comment tapped: \(id)")
      return .none

    case let .filterTapped(filter):
      state.selectedFilter = filter
      state.reportTargetCommentID = nil
      return .send(.async(.fetchPerspectives(reset: true)))

    case let .sortTapped(sort):
      state.selectedSort = sort
      state.reportTargetCommentID = nil
      return .send(.async(.fetchPerspectives(reset: true)))

    case let .likeTapped(id):
      guard let index = state.comments.firstIndex(where: { $0.id == id }),
            let commentId = state.comments[index].perspectiveId
      else { return .none }
      let wasLiked = state.comments[index].isLiked
      state.comments[index].isLiked.toggle()
      state.comments[index].likeCount += state.comments[index].isLiked ? 1 : -1
      return .send(.async(.toggleLike(commentId: commentId, currentlyLiked: wasLiked)))

    case .sendTapped:
      let text = state.commentText.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !text.isEmpty,
            let pid = state.perspectiveId,
            !state.isSubmitting
      else { return .none }
      state.isSubmitting = true
      state.commentText = ""
      return .send(.async(.createComment(perspectiveId: pid, content: text)))
    }
  }

  private func handleScopeAction(
    state: inout State,
    action: ScopeAction
  ) -> Effect<Action> {
    switch action {
    case let .customAlert(alertAction):
      switch alertAction {
      case let .presented(customAlertAction):
        switch customAlertAction {
        case .confirmTapped:
          guard let id = state.reportTargetCommentID else {
            state.customAlert = nil
            return .none
          }
          state.customAlert = nil
          return .send(.view(.reportConfirmTapped(id)))

        case .cancelTapped:
          state.reportTargetCommentID = nil
          state.customAlert = nil
          return .none
        }

      case .dismiss:
        state.reportTargetCommentID = nil
        state.customAlert = nil
        return .none
      }
    }
  }

  private func handleAsyncAction(
    state: inout State,
    action: AsyncAction
  ) -> Effect<Action> {
    switch action {
    case .fetchBattle:
      let battleId = state.battleId
      return .run { [repository = battleRepository] send in
        let result = await Result {
          try await repository.fetchBattle(battleId: battleId)
        }
        .mapError(BattleError.from)
        return await send(.inner(.battleResponse(result)))
      }
      .cancellable(id: CancelID.fetchBattle, cancelInFlight: true)

    case .fetchVoteStats:
      state.isLoadingStats = true
      let battleId = state.battleId
      return .run { [repository = battleRepository] send in
        let result = await Result {
          try await repository.fetchVoteStats(battleId: battleId)
        }
        .mapError(BattleError.from)
        return await send(.inner(.voteStatsResponse(result)))
      }
      .cancellable(id: CancelID.fetchVoteStats, cancelInFlight: true)

    case let .fetchPerspectives(reset):
      state.isLoadingComments = true
      let battleId = state.battleId
      let cursor = reset ? nil : state.nextCursor
      let optionLabel = state.selectedFilter.queryLabel
      let sort = state.selectedSort.perspectiveSort
      return .run { [repository = battleRepository] send in
        let result = await Result {
          try await repository.fetchPerspectives(
            battleId: battleId,
            cursor: cursor,
            size: 20,
            optionLabel: optionLabel,
            sort: sort
          )
        }
        .mapError(BattleError.from)
        return await send(.inner(.perspectivesResponse(result, reset: reset)))
      }
      .cancellable(id: CancelID.fetchPerspectives, cancelInFlight: true)

    case let .toggleLike(commentId, currentlyLiked):
      return .run { [repository = commentRepository] send in
        let result = await Result {
          if currentlyLiked {
            try await repository.unlikeComment(commentId: commentId)
          } else {
            try await repository.likeComment(commentId: commentId)
          }
        }
        .mapError(CommentError.from)
        return await send(.inner(.likeResponse(result)))
      }
      .cancellable(id: CancelID.toggleLike, cancelInFlight: false)

    case let .createComment(perspectiveId, content):
      return .run { [repository = perspectiveRepository] send in
        let result = await Result {
          try await repository.createComment(perspectiveId: perspectiveId, content: content)
        }
        .mapError(CommentError.from)
        return await send(.inner(.createCommentResponse(result)))
      }
      .cancellable(id: CancelID.createComment, cancelInFlight: false)
    }
  }

  private func handleInnerAction(
    state: inout State,
    action: InnerAction
  ) -> Effect<Action> {
    switch action {
    case let .battleResponse(result):
      switch result {
      case let .success(detail):
        state.title = detail.battleInfo.title
      case let .failure(error):
        Log.error("[CommentFeature] fetchBattle failed: \(error.localizedDescription)")
      }
      return .none

    case let .voteStatsResponse(result):
      state.isLoadingStats = false
      switch result {
      case let .success(stats):
        state.voteSummary = makeSummary(from: stats, fallback: state.voteSummary)
      case let .failure(error):
        Log.error("[CommentFeature] fetchVoteStats failed: \(error.localizedDescription)")
      }
      return .none

    case let .perspectivesResponse(result, reset):
      state.isLoadingComments = false
      switch result {
      case let .success(page):
        let mapped = page.items.enumerated().map { idx, item in
          CommentItem(item: item, order: idx)
        }
        state.comments = reset ? mapped : state.comments + mapped
        state.nextCursor = page.nextCursor
        state.hasNext = page.hasNext
      case let .failure(error):
        Log.error("[CommentFeature] fetchPerspectives failed: \(error.localizedDescription)")
      }
      return .none

    case let .likeResponse(result):
      switch result {
      case let .success(payload):
        if let index = state.comments.firstIndex(where: { $0.perspectiveId == payload.perspectiveId }) {
          state.comments[index].likeCount = payload.likeCount
          state.comments[index].isLiked = payload.isLiked
        }
      case let .failure(error):
        Log.error("[CommentFeature] toggleLike failed: \(error.localizedDescription)")
      }
      return .none

    case let .createCommentResponse(result):
      state.isSubmitting = false
      switch result {
      case .success:
        return .send(.async(.fetchPerspectives(reset: true)))
      case let .failure(error):
        Log.error("[CommentFeature] createComment failed: \(error.localizedDescription)")
        return .none
      }
    }
  }

  /// API 응답(BattleVoteStats) 을 화면 모델 VoteSummary 로 매핑.
  /// 옵션이 2개 이상이라 가정 — 부족하거나 매핑 실패 시 fallback 유지.
  private func makeSummary(from stats: BattleVoteStats, fallback: VoteSummary) -> VoteSummary {
    guard stats.options.count >= 2 else { return fallback }
    let a = stats.options[0]
    let b = stats.options[1]
    return VoteSummary(
      changeBadgeTitle: fallback.changeBadgeTitle,
      optionA: VoteOptionSummary(
        label: a.label ?? "A",
        title: a.title,
        representative: a.stance.isEmpty ? fallback.optionA.representative : a.stance,
        percentage: a.ratio
      ),
      optionB: VoteOptionSummary(
        label: b.label ?? "B",
        title: b.title,
        representative: b.stance.isEmpty ? fallback.optionB.representative : b.stance,
        percentage: b.ratio
      )
    )
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

  /// 서버 쿼리에 보낼 optionLabel — `all` 은 nil.
  public var queryLabel: String? {
    switch self {
    case .all: nil
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

  public var perspectiveSort: BattlePerspectiveSort {
    switch self {
    case .popular: .popular
    case .latest: .latest
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

  public static let empty = VoteSummary(
    changeBadgeTitle: "생각이 바뀌었어요",
    optionA: .init(label: "A", title: "", representative: "", percentage: 0),
    optionB: .init(label: "B", title: "", representative: "", percentage: 0)
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

public struct CommentItem: Equatable, Identifiable {
  public let id: UUID
  public var perspectiveId: Int?
  public var author: String
  public var authorImageURL: String?
  public var timeAgo: String
  public var option: CommentOption
  public var optionLabel: String?
  public var content: String
  public var replyCount: Int
  public var likeCount: Int
  public var isLiked: Bool
  public var createdOrder: Int

  public init(
    id: UUID = UUID(),
    perspectiveId: Int? = nil,
    author: String,
    authorImageURL: String? = nil,
    timeAgo: String,
    option: CommentOption,
    optionLabel: String? = nil,
    content: String,
    replyCount: Int,
    likeCount: Int,
    isLiked: Bool = false,
    createdOrder: Int
  ) {
    self.id = id
    self.perspectiveId = perspectiveId
    self.author = author
    self.authorImageURL = authorImageURL
    self.timeAgo = timeAgo
    self.option = option
    self.optionLabel = optionLabel
    self.content = content
    self.replyCount = replyCount
    self.likeCount = likeCount
    self.isLiked = isLiked
    self.createdOrder = createdOrder
  }

  /// API 응답 BattlePerspective 를 화면 모델로 변환.
  public init(item: BattlePerspective, order: Int) {
    let optionFallback: CommentOption = item.option.label == "B" ? .b : .a
    self.init(
      id: UUID(uuidString: Self.deterministicUUID(perspectiveId: item.perspectiveId)) ?? UUID(),
      perspectiveId: item.perspectiveId,
      author: item.user.nickname,
      authorImageURL: item.user.characterImageUrl,
      timeAgo: Self.relativeTimeString(from: item.createdAt),
      option: optionFallback,
      optionLabel: item.option.title,
      content: item.content,
      replyCount: item.commentCount,
      likeCount: item.likeCount,
      isLiked: item.isLiked,
      createdOrder: order
    )
  }

  private static func deterministicUUID(perspectiveId: Int) -> String {
    let hex = String(format: "%012X", perspectiveId)
    return "00000000-0000-0000-0000-\(hex)"
  }

  private static func relativeTimeString(from date: Date?) -> String {
    guard let date else { return "방금 전" }
    let interval = Date().timeIntervalSince(date)
    if interval < 60 { return "방금 전" }
    if interval < 3600 { return "\(Int(interval / 60))분 전" }
    if interval < 86400 { return "\(Int(interval / 3600))시간 전" }
    return "\(Int(interval / 86400))일 전"
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
