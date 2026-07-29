//
//  NotificationFeature.swift
//  Notification
//

import Foundation

import ComposableArchitecture
import Entity
import LogMacro
import NotificationDomainInterface
import Shared
import UseCase

@Reducer
public struct NotificationFeature {
  public init() {}

  static let pageSize = 20

  @ObservableState
  public struct State: Equatable {
    public var selectedTab: NotificationCategory = .all
    public var isLoading: Bool = false
    public var isLoadingMore: Bool = false
    public var items: [NotificationItem] = []
    public var page: Int = 0
    public var hasNext: Bool = false

    public var hasUnread: Bool {
      items.contains { !$0.isRead }
    }

    public init() {}
  }

  public enum Action: ViewAction, BindableAction {
    case binding(BindingAction<State>)
    case view(View)
    case async(AsyncAction)
    case inner(InnerAction)
    case delegate(DelegateAction)
  }

  @CasePathable
  public enum View {
    case onAppear
    case backTapped
    case tabSelected(NotificationCategory)
    case reachedBottom
    case readAllTapped
    case notificationTapped(NotificationItem)
  }

  public enum AsyncAction: Equatable {
    case fetch(reset: Bool)
    case markRead(notificationId: Int)
    case markAll
  }

  public enum InnerAction: Equatable {
    case notificationsResponse(Result<NotificationPage, NotificationError>, reset: Bool)
  }

  public enum DelegateAction: Equatable {
    case dismiss
  }

  nonisolated enum CancelID: Hashable {
    case fetch
  }

  @Dependency(\.notificationUseCase) private var notificationUseCase
  @Dependency(\.analyticsUseCase) private var analyticsUseCase

  public var body: some Reducer<State, Action> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .binding:
        return .none

      case let .view(viewAction):
        return handleViewAction(state: &state, action: viewAction)

      case let .async(asyncAction):
        return handleAsyncAction(state: &state, action: asyncAction)

      case let .inner(innerAction):
        return handleInnerAction(state: &state, action: innerAction)

      case let .delegate(delegateAction):
        return handleDelegateAction(state: &state, action: delegateAction)
      }
    }
  }
}

extension NotificationFeature {
  private func handleViewAction(
    state: inout State,
    action: View
  ) -> Effect<Action> {
    switch action {
    case .onAppear:
      analyticsUseCase.track(.screenView(screen: .notification, referrer: nil))
      guard state.items.isEmpty else { return .none }
      analyticsUseCase.track(.notificationAction(NotificationActionData(action: .viewList)))
      return .send(.async(.fetch(reset: true)))

    case .backTapped:
      return .send(.delegate(.dismiss))

    case let .tabSelected(tab):
      guard tab != state.selectedTab else { return .none }
      state.selectedTab = tab
      state.items = []
      state.page = 0
      state.hasNext = false
      return .send(.async(.fetch(reset: true)))

    case .reachedBottom:
      guard state.hasNext, !state.isLoadingMore, !state.isLoading else { return .none }
      return .send(.async(.fetch(reset: false)))

    case .readAllTapped:
      analyticsUseCase.track(.notificationAction(NotificationActionData(
        action: .readAll,
        unreadCount: state.items.count(where: { !$0.isRead })
      )))
      // 리스트를 낙관적으로 읽음 처리. 홈/탐색/프로필 벨 배지는 각 화면 재진입 시 /unread 로 갱신된다.
      state.items = state.items.map { $0.markedAsRead() }
      return .send(.async(.markAll))

    case let .notificationTapped(item):
      analyticsUseCase.track(.notificationAction(NotificationActionData(action: .itemTap)))
      var effects: [Effect<Action>] = []

      // 미읽음일 때만 읽음 처리.
      if !item.isRead {
        if let index = state.items.firstIndex(where: { $0.id == item.id }) {
          state.items[index] = state.items[index].markedAsRead()
        }
        effects.append(.send(.async(.markRead(notificationId: item.notificationId))))
      }

      // detailCode 기반 딥링크 라우팅 (이미 읽은 항목도 이동).
      if let deeplink = PickeDeeplinkParser.parse(
        detailCode: item.detailCode,
        referenceId: item.referenceId,
        perspectiveId: item.perspectiveId
      ) {
        effects.append(.run { _ in
          NotificationCenter.default.post(
            name: .pickeDeeplink,
            object: nil,
            userInfo: ["deeplink": deeplink.encoded]
          )
        })
      }

      return .merge(effects)
    }
  }

  private func handleAsyncAction(
    state: inout State,
    action: AsyncAction
  ) -> Effect<Action> {
    switch action {
    case let .fetch(reset):
      if reset {
        state.isLoading = true
      } else {
        state.isLoadingMore = true
      }
      let page = reset ? 0 : state.page
      let category = state.selectedTab
      return .run { [useCase = notificationUseCase] send in
        let result = await Result {
          try await useCase.fetchNotifications(
            category: category,
            page: page,
            size: Self.pageSize
          )
        }
        .mapError(NotificationError.from)
        return await send(.inner(.notificationsResponse(result, reset: reset)))
      }
      .cancellable(id: CancelID.fetch, cancelInFlight: true)

    case let .markRead(notificationId):
      return .run { [useCase = notificationUseCase] _ in
        try? await useCase.markAsRead(notificationId: notificationId)
      }

    case .markAll:
      // 벨 배지는 각 화면 재진입 시 /unread 로 갱신되므로 여기선 서버 반영만(fire-and-forget).
      return .run { [useCase = notificationUseCase] _ in
        _ = try? await useCase.markAllAsRead()
      }
    }
  }

  private func handleInnerAction(
    state: inout State,
    action: InnerAction
  ) -> Effect<Action> {
    switch action {
    case let .notificationsResponse(result, reset):
      state.isLoading = false
      state.isLoadingMore = false
      switch result {
      case let .success(pageData):
        if reset {
          state.items = pageData.items
        } else {
          state.items.append(contentsOf: pageData.items)
        }
        state.hasNext = pageData.hasNext
        if pageData.hasNext { state.page += 1 }
      case let .failure(error):
        Log.error("[NotificationFeature] fetchNotifications failed: \(error.localizedDescription)")
      }
      return .none
    }
  }

  private func handleDelegateAction(
    state _: inout State,
    action: DelegateAction
  ) -> Effect<Action> {
    switch action {
    case .dismiss:
      return .none
    }
  }
}
