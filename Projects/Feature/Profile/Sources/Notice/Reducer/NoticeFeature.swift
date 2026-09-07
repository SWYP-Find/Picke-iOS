//
//  NoticeFeature.swift
//  Profile
//

import Foundation
import PickeCoreLogger

import ComposableArchitecture
import NotificationDomainInterface
import ProfileDomainInterface

@Reducer
public struct NoticeFeature {
  public init() {}

  @Dependency(\.notificationUseCase) private var notificationUseCase

  @ObservableState
  public struct State: Equatable {
    public var selectedTab: NoticeTab = .notice

    public var noticeItems: [NotificationItem] = []
    public var eventItems: [NotificationItem] = []
    /// 화면이 스켈레톤을 보일지 콘텐츠를 보일지 가르는 상태.
    public enum ViewState: Equatable {
      case loading
      case loaded
    }

    public var viewState: ViewState = .loaded
    /// 선택된 항목 — nil 이 아니면 상세 콘텐츠 표시.
    public var selectedItem: NotificationItem?

    public init() {}

    /// 현재 탭의 목록.
    public var currentItems: [NotificationItem] {
      switch selectedTab {
      case .notice: noticeItems
      case .event: eventItems
      }
    }
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
    case tabSelected(NoticeTab)
    case itemTapped(NotificationItem)
    /// 상세 → 목록.
    case backToListTapped
  }

  public enum AsyncAction: Equatable {
    case fetchLists
    case markAsRead(notificationId: Int)
  }

  public enum InnerAction: Equatable {
    case listsResponse(notices: [NotificationItem], events: [NotificationItem])
    case listsFailed
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

extension NoticeFeature {
  private func handleViewAction(
    state: inout State,
    action: View
  ) -> Effect<Action> {
    switch action {
    case .onAppear:
      guard state.noticeItems.isEmpty, state.eventItems.isEmpty else { return .none }
      state.viewState = .loading
      return .send(.async(.fetchLists))

    case .backTapped:
      // 상세 표시 중이면 목록으로 복귀, 아니면 화면 닫기.
      if state.selectedItem != nil {
        state.selectedItem = nil
        return .none
      }
      return .send(.delegate(.dismiss))

    case let .tabSelected(tab):
      state.selectedTab = tab
      return .none

    case let .itemTapped(item):
      state.selectedItem = item
      guard !item.isRead else { return .none }
      markRead(state: &state, notificationId: item.notificationId)
      return .send(.async(.markAsRead(notificationId: item.notificationId)))

    case .backToListTapped:
      state.selectedItem = nil
      return .none
    }
  }

  private func handleAsyncAction(
    state _: inout State,
    action: AsyncAction
  ) -> Effect<Action> {
    switch action {
    case .fetchLists:
      return .run { send in
        do {
          async let notices = notificationUseCase.fetchNotifications(
            category: .notice, page: 0, size: 50
          )
          async let events = notificationUseCase.fetchNotifications(
            category: .event, page: 0, size: 50
          )
          let (noticePage, eventPage) = try await (notices, events)
          await send(.inner(.listsResponse(notices: noticePage.items, events: eventPage.items)))
        } catch {
          PickeLogger.error("[NoticeFeature] fetchLists failed: \(error.localizedDescription)", category: .ui)
          await send(.inner(.listsFailed))
        }
      }

    case let .markAsRead(notificationId):
      return .run { _ in
        try? await notificationUseCase.markAsRead(notificationId: notificationId)
      }
    }
  }

  private func handleInnerAction(
    state: inout State,
    action: InnerAction
  ) -> Effect<Action> {
    switch action {
    case let .listsResponse(notices, events):
      state.viewState = .loaded
      state.noticeItems = notices
      state.eventItems = events
      return .none

    case .listsFailed:
      state.viewState = .loaded
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

  /// 목록/선택 항목의 읽음 상태를 로컬 갱신.
  private func markRead(state: inout State, notificationId: Int) {
    func updated(_ items: [NotificationItem]) -> [NotificationItem] {
      items.map { item in
        guard item.notificationId == notificationId else { return item }
        return NotificationItem(
          notificationId: item.notificationId,
          category: item.category,
          detailCode: item.detailCode,
          title: item.title,
          body: item.body,
          referenceId: item.referenceId,
          perspectiveId: item.perspectiveId,
          isRead: true,
          createdAt: item.createdAt
        )
      }
    }
    state.noticeItems = updated(state.noticeItems)
    state.eventItems = updated(state.eventItems)
  }
}
