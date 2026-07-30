//
//  HifiFeature.swift
//  Hifi
//

import Foundation
import SearchDomainInterface

import ComposableArchitecture
import HifiInterface
import HomeDomainInterface
import LogMacro
import NotificationDomainInterface
import AnalyticsServiceInterface
import BattleDomainInterface

@Reducer
public struct HifiFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public var categories: [ExploreCategory] = ExploreCategory.allCases
    public var selectedCategory: ExploreCategory = .all
    public var selectedSort: ExploreSort = .popular
    public var items: [ExploreItem] = []
    public var isLoading: Bool = false
    public var nextOffset: Int?
    public var hasNext: Bool = false

    /// 종 아이콘 빨간점 — 미읽음 알림 존재 여부. 화면 진입마다 /unread 서버값으로 갱신(저장 안 함).
    public var hasUnreadNotification: Bool = false

    public init() {}
  }

  public enum Action: ViewAction {
    case view(View)
    case async(AsyncAction)
    case inner(InnerAction)
    case delegate(HifiDelegate)
  }

  @CasePathable
  public enum View {
    case onAppear
    case categoryTapped(ExploreCategory)
    case swipedCategory(forward: Bool)
    case sortTapped(ExploreSort)
    case itemTapped(id: Int)
    case reachedBottom
    case notificationTapped
    /// 탐색 화면 배너 광고 클릭
    case adBannerClicked
  }

  public enum AsyncAction: Equatable {
    case searchRequested(reset: Bool)
    /// 벨 배지용 미읽음 여부 서버 동기화 (GET /api/v1/notifications/unread).
    case syncUnreadBadge
  }

  public enum InnerAction: Equatable {
    case searchResponse(Result<ExploreItemPage, BattleError>, reset: Bool)
    case unreadBadgeResponse(Bool)
  }

  nonisolated enum CancelID: Hashable {
    case search
    case syncUnreadBadge
  }

  @Dependency(\.searchUseCase) private var searchUseCase
  @Dependency(\.notificationUseCase) private var notificationUseCase
  @Dependency(\.analyticsUseCase) private var analyticsUseCase

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
      }
    }
  }
}

extension HifiFeature {
  private func handleViewAction(
    state: inout State,
    action: View
  ) -> Effect<Action> {
    switch action {
    case .onAppear:
      analyticsUseCase.track(.screenView(screen: .explore, referrer: nil))
      // 벨 배지는 진입/재진입마다 서버(/unread)로 갱신 — 저장값 없이 서버 진실값만 사용.
      return .merge(
        .send(.async(.searchRequested(reset: true))),
        .send(.async(.syncUnreadBadge))
      )

    case let .categoryTapped(category):
      state.selectedCategory = category
      return .send(.async(.searchRequested(reset: true)))

    case let .swipedCategory(forward):
      // 좌우 스와이프 → 인접 카테고리로 전환 (범위 벗어나면 무시)
      guard let next = adjacentCategory(in: state, forward: forward) else { return .none }
      state.selectedCategory = next
      return .send(.async(.searchRequested(reset: true)))

    case let .sortTapped(sort):
      state.selectedSort = sort
      return .send(.async(.searchRequested(reset: true)))

    case let .itemTapped(id):
      return .send(.delegate(.openBattle(battleId: id)))

    case .notificationTapped:
      return .send(.delegate(.openNotification))

    case .reachedBottom:
      // 무한 스크롤: 다음 페이지가 있고 로딩 중이 아니면 추가 로드.
      guard state.hasNext, !state.isLoading else { return .none }
      return .send(.async(.searchRequested(reset: false)))

    case .adBannerClicked:
      analyticsUseCase.track(.adClick(AdClickData(placement: .explore, format: .banner, unit: "ADFIT_BANNER_320X100")))
      return .none
    }
  }

  /// 현재 선택된 카테고리 기준 인접 카테고리(스와이프 방향). 끝에서는 순환(역사→전체, 전체→역사).
  private func adjacentCategory(in state: State, forward: Bool) -> ExploreCategory? {
    let all = state.categories
    guard !all.isEmpty, let idx = all.firstIndex(of: state.selectedCategory) else { return nil }
    let count = all.count
    let nextIdx = forward ? (idx + 1) % count : (idx - 1 + count) % count
    return all[nextIdx]
  }

  private func handleAsyncAction(
    state: inout State,
    action: AsyncAction
  ) -> Effect<Action> {
    switch action {
    case let .searchRequested(reset):
      state.isLoading = true
      if reset { state.items = [] }
      let category = state.selectedCategory.queryValue
      let sort = state.selectedSort.queryValue
      let offset = reset ? 0 : (state.nextOffset ?? 0)
      return .run { [useCase = searchUseCase] send in
        let result = await Result {
          try await useCase.searchBattles(category: category, sort: sort, offset: offset, size: 20)
        }
        .mapError(BattleError.from)
        return await send(.inner(.searchResponse(result, reset: reset)))
      }
      .cancellable(id: CancelID.search, cancelInFlight: true)

    case .syncUnreadBadge:
      return .run { [useCase = notificationUseCase] send in
        guard let hasUnread = try? await useCase.hasUnreadNotifications() else { return }
        await send(.inner(.unreadBadgeResponse(hasUnread)))
      }
      .cancellable(id: CancelID.syncUnreadBadge, cancelInFlight: true)
    }
  }

  private func handleInnerAction(
    state: inout State,
    action: InnerAction
  ) -> Effect<Action> {
    switch action {
    case let .searchResponse(result, reset):
      state.isLoading = false
      switch result {
      case let .success(page):
        state.items = reset ? page.items : state.items + page.items
        state.nextOffset = page.nextOffset
        state.hasNext = page.hasNext
      case let .failure(error):
        Log.error("[HifiFeature] searchBattles failed: \(error.localizedDescription)")
        if reset { state.items = [] }
      }
      return .none

    case let .unreadBadgeResponse(hasUnread):
      // 서버(/unread) 값을 그대로 반영 — 별도 저장/가드 없이 진입 시점 진실값만 사용.
      state.hasUnreadNotification = hasUnread
      return .none
    }
  }
}
