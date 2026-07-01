//
//  ProfileFeature.swift
//  Profile
//
//  마이페이지 루트 기능 — picke.pen `마이페이지_잠금`.
//  프로필 카드(닉네임/잠금) + 포인트 충전 + 나의 철학자 유형 + 메뉴 리스트.
//  프로필/포인트 조회 API 연동 전까지는 기본(목) 값 노출.
//

import Foundation

import ComposableArchitecture
import Entity
import LogMacro
import UseCase

@Reducer
public struct ProfileFeature {
  public init() {}

  /// 마이페이지 메뉴 항목 — picke.pen 기준.
  public enum MenuItem: String, CaseIterable, Equatable, Identifiable {
    case battleHistory = "내 배틀 기록"
    case contentActivity = "내 콘텐츠 활동"
    case noticeEvent = "공지방 · 이벤트"

    public var id: String { rawValue }
  }

  @ObservableState
  public struct State: Equatable {
    public var isLoading: Bool = false
    /// 닉네임 — /me/mypage 응답에서 주입.
    public var nickname: String = ""
    /// 사용자 코드 (앞에 `@` 표기) — /me/mypage 응답에서 주입.
    public var userCode: String = ""
    /// 보유 포인트 — /me/mypage 응답에서 주입.
    public var point: Int = 0
    /// 나의 철학자 유형명(예: `칸트형`) — 미확정 시 nil → `??형`.
    public var philosopherType: String?
    /// 철학자 라벨(예: `원칙주의자`).
    public var philosopherLabel: String = ""
    /// 철학자 이미지 URL.
    public var philosopherImageURL: String?
    /// 프로필 이미지 URL (없으면 기본 아바타).
    public var profileImageURL: String?
    /// 메뉴 목록.
    public var menuItems: [MenuItem] = MenuItem.allCases

    /// 종 아이콘 빨간점 — 미읽음 알림 존재 여부 (알림 화면과 전역 공유).
    @Shared(.appStorage("HasUnreadNotification")) public var hasUnreadNotification: Bool = false

    public init() {}

    /// 철학자 유형 미확정(잠금) 여부.
    public var isPhilosopherLocked: Bool {
      philosopherType?.isEmpty ?? true
    }

    /// 표시용 철학자 유형 — 잠금 시 `??형`, 아니면 `유형명 · 라벨`.
    public var philosopherDisplay: String {
      guard let type = philosopherType, !type.isEmpty else { return "??형" }
      return philosopherLabel.isEmpty ? type : "\(type) · \(philosopherLabel)"
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
    case notificationTapped
    case settingsTapped
    case profileTapped
    case chargePointTapped
    case freeChargeTapped
    case philosopherTapped
    case menuTapped(MenuItem)
  }

  public enum AsyncAction: Equatable {
    case fetchProfile
  }

  public enum InnerAction: Equatable {
    case myPageResponse(Result<MyPage, ProfileError>)
  }

  public enum DelegateAction: Equatable {
    /// 상단 백탭 → 직전 탭으로 복귀.
    case backToHome
    /// 알림함 이동.
    case openNotification
    /// 설정 화면 이동.
    case openSettings(nickname: String)
    /// 프로필 카드 탭 → 편집.
    case editProfile
    /// 포인트 충전.
    case chargePoint
    /// 나의 철학자 유형 상세.
    case openPhilosopher
    /// 메뉴 항목 선택.
    case menuSelected(MenuItem)
  }

  nonisolated enum CancelID: Hashable {
    case fetchProfile
  }

  @Dependency(\.profileUseCase) private var profileUseCase
  @Dependency(\.rewardedAdClient) private var rewardedAdClient
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

extension ProfileFeature {
  private func handleViewAction(
    state: inout State,
    action: View
  ) -> Effect<Action> {
    switch action {
    case .onAppear:
      analyticsUseCase.track(.screenView(screen: .mypage, referrer: nil))
      return .send(.async(.fetchProfile))

    case .backTapped:
      return .send(.delegate(.backToHome))

    case .notificationTapped:
      analyticsUseCase.track(.uiAction(action: .mypageNotification, screen: .mypage))
      return .send(.delegate(.openNotification))

    case .settingsTapped:
      analyticsUseCase.track(.uiAction(action: .mypageSettings, screen: .mypage))
      return .send(.delegate(.openSettings(nickname: state.nickname)))

    case .profileTapped:
      return .send(.delegate(.editProfile))

    case .chargePointTapped:
      analyticsUseCase.track(.uiAction(action: .pointCharge, screen: .mypage))
      return .send(.delegate(.chargePoint))

    case .freeChargeTapped:
      // 무료 충전 → 리워드 광고 표시, 보상 획득 시 ad_revenue 트래킹 + 포인트 갱신.
      return .run { [rewardedAdClient, analyticsUseCase] send in
        let earned = await rewardedAdClient.showRewardedAd()
        if earned {
          analyticsUseCase.track(.adRevenue(placement: .charge))
          await send(.async(.fetchProfile))
        }
      }

    case .philosopherTapped:
      return .send(.delegate(.openPhilosopher))

    case let .menuTapped(item):
      return .send(.delegate(.menuSelected(item)))
    }
  }

  private func handleAsyncAction(
    state: inout State,
    action: AsyncAction
  ) -> Effect<Action> {
    switch action {
    case .fetchProfile:
      state.isLoading = true
      return .run { [useCase = profileUseCase] send in
        let result = await Result {
          try await useCase.fetchMyPage()
        }
        .mapError(ProfileError.from)
        return await send(.inner(.myPageResponse(result)))
      }
      .cancellable(id: CancelID.fetchProfile, cancelInFlight: true)
    }
  }

  private func handleInnerAction(
    state: inout State,
    action: InnerAction
  ) -> Effect<Action> {
    switch action {
    case let .myPageResponse(result):
      state.isLoading = false
      switch result {
      case let .success(myPage):
        state.nickname = myPage.profile.nickname
        state.userCode = myPage.profile.userTag
        state.point = myPage.tier.currentPoint
        state.philosopherType = myPage.philosopher.typeName.isEmpty ? nil : myPage.philosopher.typeName
        state.philosopherLabel = myPage.philosopher.philosopherLabel
        state.philosopherImageURL = myPage.philosopher.imageURL.isEmpty ? nil : myPage.philosopher.imageURL
        state.profileImageURL = myPage.profile.characterImageURL.isEmpty ? nil : myPage.profile.characterImageURL
      case let .failure(error):
        Log.error("[ProfileFeature] fetchMyPage failed: \(error.localizedDescription)")
      }
      return .none
    }
  }

  /// delegate 는 부모(ProfileCoordinator / MainTab)가 처리 — Feature 는 발행만 한다.
  private func handleDelegateAction(
    state _: inout State,
    action: DelegateAction
  ) -> Effect<Action> {
    switch action {
    case .backToHome:
      return .none

    case .openNotification:
      return .none

    case .openSettings:
      return .none

    case .editProfile:
      return .none

    case .chargePoint:
      return .none

    case .openPhilosopher:
      return .none

    case .menuSelected:
      return .none
    }
  }
}
