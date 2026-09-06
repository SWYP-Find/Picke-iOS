//
//  AppReducer.swift
//  Picke
//
//  Created by Wonji Suh  on 5/6/26.
//

import AnalyticsServiceInterface
import ComposableArchitecture
import DomainAssembly
import LogMacro
import PickeCore
import FeatureAssembly

@Reducer
public struct AppReducer: Sendable {
  public init() {}

  @ObservableState
  public enum State {
    case splash(SplashFeature.State)
    case auth(AppAuthCoordinator.State)
    case mainTab(AppMainTabCoordinator.State)

    public init() {
      self = .splash(SplashFeature.State())
    }

    // Animation identifier for SwiftUI transitions
    var animationID: String {
      switch self {
      case .splash: return "splash"
      case .auth: return "auth"
      case .mainTab: return "mainTab"
      }
    }
  }

  // MARK: - Action

  public enum Action: ViewAction {
    case view(View)
    case async(AsyncAction)
    case inner(InnerAction)
    case navigation(NavigationAction)
    case scope(ScopeAction)
  }

  @CasePathable
  public enum View {
    case presentView
    case presentRoot
    case presentAuth
    /// 앱 시작 전면 팝업 광고 클릭.
    case appStartAdClicked
  }

  // MARK: - 앱내에서 사용하는 액션

  public enum InnerAction: Equatable {
    case completeAuthTransition
    case completeMainTabTransition
  }

  // MARK: - 비동기 처리 액션

  public enum AsyncAction: Equatable {
    case startNotificationListener
    case refreshTokenExpired
    case observeDeeplink
    case deeplinkReceived(PickeDeeplink)
  }

  // MARK: - 네비게이션 연결 액션

  public enum NavigationAction: Equatable {}

  // MARK: - 스코프 액션

  @CasePathable
  public enum ScopeAction {
    case splash(SplashFeature.Action)
    case auth(AppAuthCoordinator.Action)
    case mainTab(AppMainTabCoordinator.Action)
  }

  @Dependency(\.continuousClock) var clock
  @Dependency(\.analyticsUseCase) private var analyticsUseCase

  // 🎯 PFW 패턴: 강타입 최소 CancelID (3개로 축소)
  private enum CancelID: Hashable {
    case coordinator(CoordinatorType)
    case transition
    case refreshTokenListener
    case deeplinkListener

    enum CoordinatorType: Hashable {
      case auth
    }
  }

  // 🎯 PFW 패턴: 최소한의 핵심 취소 (3개만)
  private func cancelAllCoordinatorEffects() -> Effect<Action> {
    return .merge([
      // PFW 권장: 최소한의 핵심 Coordinator Effect 취소
//      .cancel(id: CancelID.coordinator(.staff)),
//      .cancel(id: CancelID.coordinator(.member)),
      .cancel(id: CancelID.coordinator(.auth)),

//
    ])
  }

  // 🎯 PFW 패턴: 상태 변경 전에 effect 취소를 먼저 완료
  private func startTransition(_ action: InnerAction) -> Effect<Action> {
    .concatenate(
      cancelAllCoordinatorEffects(),
      .run { _ in await Task.yield() },
      .send(.inner(action))
    )
    .cancellable(id: CancelID.transition, cancelInFlight: true)
  }

  // 제거됨: PFW 권장사항에 따라 단순화

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case let .view(viewAction):
        return handleViewAction(state: &state, action: viewAction)

      case let .inner(innerAction):
        return handleInnerAction(state: &state, action: innerAction)

      case let .async(asyncAction):
        return handleAsyncAction(state: &state, action: asyncAction)

      case let .navigation(navigationAction):
        return handleNavigationAction(state: &state, action: navigationAction)

      case let .scope(scopeAction):
        return handleScopeAction(state: &state, action: scopeAction)
      }
    }
  }

  private func handleViewAction(
    state _: inout State,
    action: View
  ) -> Effect<Action> {
    switch action {
    case .presentView:
      return .merge(
        .run { send in
          await send(.scope(.splash(.view(.onAppear))))
        },
        observeDeeplink()
      )

    case .presentRoot:
      return startTransition(.completeMainTabTransition)

    case .presentAuth:
      return startTransition(.completeAuthTransition)

    case .appStartAdClicked:
      analyticsUseCase.track(.adClick(AdClickData(placement: .appStart, format: .popup)))
      return .none
    }
  }

  private func handleAsyncAction(
    state: inout State,
    action: AsyncAction
  ) -> Effect<Action> {
    switch action {
    case .startNotificationListener:
      // 토큰 만료 리스너 + 인앱/푸시 딥링크 리스너를 함께 구동.
      return .merge(
        setupRefreshTokenExpiredListener()
          .cancellable(id: CancelID.refreshTokenListener, cancelInFlight: true),
        observeDeeplink()
      )

    case .refreshTokenExpired:
      return startTransition(.completeAuthTransition)

    case .observeDeeplink:
      return observeDeeplink()

    case let .deeplinkReceived(deeplink):
      // 메인 진입 상태에서만 즉시 라우팅. 그 외에는 pending(UserDefaults)으로 보류.
      guard case .mainTab = state else { return .none }
      switch deeplink {
      case let .battle(battleId):
        // 홈 탭 전환 후 HomeCoordinator(Chat 보유)가 배틀 상세 push.
        return .merge(
          .send(.scope(.mainTab(.selectTab(AppMainTabCoordinator.Tab.home.rawValue)))),
          .send(.scope(.mainTab(.home(.view(.openBattle(battleId: battleId))))))
        )
      case let .perspective(perspectiveId, commentId):
        // 홈 탭 전환 후 HomeCoordinator(Chat 보유)가 관점(답글) 화면 push.
        return .merge(
          .send(.scope(.mainTab(.selectTab(AppMainTabCoordinator.Tab.home.rawValue)))),
          .send(.scope(.mainTab(.home(.view(.openPerspective(perspectiveId: perspectiveId, commentId: commentId))))))
        )
      case .point:
        // 마이페이지 탭 전환 후 포인트 내역 push.
        return .merge(
          .send(.scope(.mainTab(.selectTab(AppMainTabCoordinator.Tab.myPage.rawValue)))),
          .send(.scope(.mainTab(.myPage(.view(.openPointHistory)))))
        )
      case .terms:
        // 마이페이지 탭 전환 후 서비스 약관 웹뷰 push.
        return .merge(
          .send(.scope(.mainTab(.selectTab(AppMainTabCoordinator.Tab.myPage.rawValue)))),
          .send(.scope(.mainTab(.myPage(.view(.openTerms)))))
        )
      }
    }
  }

  private func handleInnerAction(
    state: inout State,
    action: InnerAction
  ) -> Effect<Action> {
    switch action {
    case .completeAuthTransition:
      state = .auth(.init())
      return .none

    case .completeMainTabTransition:
      state = .mainTab(.init())
      // 콜드 스타트/로그인 직후 대기 중이던 딥링크 소비.
      if let pending = PushDeeplinkBridge.consumePending() {
        return .send(.async(.deeplinkReceived(pending)))
      }
      return .none
    }
  }

  private func handleNavigationAction(
    state _: inout State,
    action _: NavigationAction
  ) -> Effect<Action> {
    return .none
  }

  // 🎯 PFW 철학: 단순하고 조합 가능한 상태 검증
  private func isValidAction(
    _ action: ScopeAction,
    for state: State
  ) -> Bool {
    switch (action, state) {
    case (.auth, .auth), (.splash, .splash), (.mainTab, .mainTab):
      return true
    default:
      return false
    }
  }

  private func handleScopeAction(
    state: inout State,
    action: ScopeAction
  ) -> Effect<Action> {
    guard isValidAction(action, for: state) else { return .none }

    let childEffect = reduceChild(state: &state, action: action)
    let navigationEffect = handleScopeNavigation(action: action)
    return .merge(childEffect, navigationEffect)
  }

  private func reduceChild(
    state: inout State,
    action: ScopeAction
  ) -> Effect<Action> {
    switch (state, action) {
    case var (.splash(childState), .splash(childAction)):
      let effect = SplashFeature()
        .reduce(into: &childState, action: childAction)
        .map { Action.scope(.splash($0)) }
      state = .splash(childState)
      return effect

    case var (.auth(childState), .auth(childAction)):
      let effect = AppAuthCoordinator()
        .reduce(into: &childState, action: childAction)
        .map { Action.scope(.auth($0)) }
      state = .auth(childState)
      return effect

    case var (.mainTab(childState), .mainTab(childAction)):
      let effect = AppMainTabCoordinator()
        .reduce(into: &childState, action: childAction)
        .map { Action.scope(.mainTab($0)) }
      state = .mainTab(childState)
      return effect

    default:
      return .none
    }
  }

  // 🎯 PFW 패턴: 네비게이션 로직 분리
  private func handleScopeNavigation(action: ScopeAction) -> Effect<Action> {
    switch action {
    case .splash(.view(.onAppear)):
      return .none

    case .splash(.delegate(.presentAuth)):
      return .run { send in
        try await clock.sleep(for: .seconds(3))
        try await send(.view(.presentAuth))
      }

    case .splash(.delegate(.presentMainTab)):
      return .run { send in
        try await clock.sleep(for: .seconds(3))
        try await send(.view(.presentRoot))
      }

    case .auth(.navigation(.presentMainTab)):
      // 로그인 성공 → 메인 진입 + APNs 디바이스 토큰 서버 등록.
      return .merge(
        .send(.view(.presentRoot)),
        .run { _ in await PushTokenStore.register() }
      )

    // 로그아웃/탈퇴 → 로그인 화면으로 복귀
    case .mainTab(.delegate(.sessionEnded)):
      return .send(.view(.presentAuth))

    default:
      return .none
    }
  }

  private func isSplashState(_ state: State) -> Bool {
    guard case .splash = state else { return false }
    return true
  }

  /// 푸시/인앱 알림 탭으로 브로드캐스트된 딥링크를 수신해 라우팅 액션으로 변환.
  private func observeDeeplink() -> Effect<Action> {
    .run { send in
      for await notification in NotificationCenter.default.notifications(named: .pickeDeeplink) {
        guard let encoded = notification.userInfo?["deeplink"] as? String,
              let deeplink = PickeDeeplinkParser.parse(urlString: encoded) else { continue }
        await send(.async(.deeplinkReceived(deeplink)))
      }
    }
    .cancellable(id: CancelID.deeplinkListener, cancelInFlight: true)
  }

  private func setupRefreshTokenExpiredListener() -> Effect<Action> {
    return .publisher {
      NotificationCenter.default
        .publisher(for: NSNotification.Name("RefreshTokenExpired"))
        .map { _ in Action.async(.refreshTokenExpired) }
    }
    .cancellable(id: CancelID.refreshTokenListener, cancelInFlight: true)
  }
}
