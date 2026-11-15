//
//  HomeFeature.swift
//  Home
//
//  Created by Picke on 5/15/26.
//

import AttendanceDomainInterface
import AuthDomainInterface
import ComposableArchitecture
import Foundation
import HomeDomainInterface
import HomeInterface
import NotificationDomainInterface
import PickeAnalyticsInterface
import PickeCoreLogger
import PickeCoreUtility

@Reducer
public struct HomeFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    /// 화면이 스켈레톤을 보일지 콘텐츠를 보일지 가르는 상태.
    public enum ViewState: Equatable {
      case loading
      case loaded
      /// 로딩이 실패한 상태(받아 둔 데이터는 유지) — 데이터가 없으면 스켈레톤이 아니라 빈 상태를 보여준다(Android와 동일).
      case failed
    }

    public var viewState: ViewState = .loaded
    public var hasLoadedHome: Bool = false
    public var newNotice: Bool = false
    public var heroes: [HeroBattle] = []
    public var heroIndex: Int = 0
    public var hotBattles: [HotBattle] = []
    public var bestBattles: [BestBattle] = []
    public var bestComments: [HomeBestComment] = []
    public var newBattles: [NewBattle] = []

    /// 종 아이콘 빨간점 — 미읽음 알림 존재 여부. 화면 진입마다 /unread 서버값으로 갱신(저장 안 함).
    public var hasUnreadNotification: Bool = false
    /// 첫 /unread 결과가 오기 전까지 true — 그동안 종 자리에 shimmer 원을 그린다(Android isAlarmStatusLoading).
    public var isUnreadBadgeLoading: Bool = true

    /// 홈 조회 실패 안내 — View 가 토스트로 띄운 뒤 `.toastShown` 으로 비운다.
    public var toastMessage: String?

    /// 출석체크 커스텀 모달 — 오늘 첫 출석에 성공했을 때만 값이 찬다.
    @Presents public var attendanceModal: AttendanceModalFeature.State?
    /// 출석 체크는 앱 세션당 1회만 시도한다(하루 1회 제한이라 재진입마다 때릴 이유가 없다).
    public var hasTriedAttendance: Bool = false

    /// 홈 탭 재선택 시 맨 위로 올리라는 요청 토큰(값이 바뀔 때마다 View 가 스크롤).
    public var scrollToTopRequest: Int = 0

    /// Android 상단 바: 첫 로딩 중이거나 미읽음 조회 전이면 종 대신 shimmer 원(`isLoading || isAlarmStatusLoading`).
    public var shouldShowBellSkeleton: Bool {
      shouldShowSkeleton || isUnreadBadgeLoading
    }

    /// Best 배틀은 최대 3개만 노출한다(Android `take(3)`).
    public var visibleBestBattles: [BestBattle] {
      Array(bestBattles.prefix(3))
    }

    public var hasVisibleHomeContent: Bool {
      !heroes.isEmpty || !hotBattles.isEmpty || !bestBattles.isEmpty ||
        !bestComments.isEmpty || !newBattles.isEmpty
    }

    public var shouldShowSkeleton: Bool {
      viewState != .failed &&
        (viewState == .loading || !hasLoadedHome) &&
        heroes.isEmpty &&
        hotBattles.isEmpty &&
        bestBattles.isEmpty &&
        bestComments.isEmpty &&
        newBattles.isEmpty
    }

    public init() {}
  }

  public enum Action: ViewAction, BindableAction {
    case binding(BindingAction<State>)
    case view(View)
    case async(AsyncAction)
    case inner(InnerAction)
    case delegate(HomeDelegate)
    case attendanceModal(PresentationAction<AttendanceModalFeature.Action>)
  }

  @CasePathable
  public enum View {
    case onAppear
    case pullToRefresh
    case heroTapped(HeroBattle)
    case hotBattleTapped(HotBattle)
    case bestBattleTapped(BestBattle)
    case bestCommentTapped(HomeBestComment)
    case newBattleTapped(NewBattle)
    case notificationTapped
    /// 홈 피드 네이티브 광고 클릭
    case adNativeClicked
    /// 홈 루트에서 홈 탭을 다시 눌렀을 때 — 맨 위로만 이동한다(Android 와 동일, 다시 불러오지 않음).
    case homeTabReselected
    /// 실패 토스트를 띄운 뒤 메시지를 비운다.
    case toastShown
    /// 앱이 다시 활성화됨 — Android `AppLifecycleObserver.onStart` 처럼 오늘 출석이 안 됐으면 체크한다.
    case appBecameActive
  }

  @CasePathable
  public enum AsyncAction: Equatable {
    case fetchHome
    /// 당겨서 새로고침 — 스켈레톤 없이 받아 둔 화면 위에서 다시 조회한다.
    case refreshHome
    /// 벨 배지용 미읽음 여부 서버 동기화 (GET /api/v1/notifications/unread).
    case syncUnreadBadge
    /// 출석 체크 후 주간 현황을 조회해 시트를 띄운다(Android `checkInAndShowAttendanceSheetIfNeeded`).
    case checkAttendance(day: String)
    /// 시트 없이 출석 체크만 한다(Android `checkAttendanceIfNeeded`).
    case checkAttendanceOnly(day: String)
  }

  @CasePathable
  public enum InnerAction: Equatable {
    case homeResponse(Result<HomeBundle, AuthError>)
    case unreadBadgeResponse(Result<Bool, AuthError>)
    /// 주간 현황 조회까지 끝난 결과(체크 성공 여부와 관계없이 시트를 띄운다).
    case attendanceResponse(day: String, weekly: WeeklyAttendance, pointsEarned: Int)
    /// 출석 체크 성공 — 오늘 날짜를 기록해 하루 1회만 부른다.
    case attendanceChecked(day: String)
  }

  nonisolated enum CancelID: Hashable {
    case fetchHome
    case syncUnreadBadge
    case attendance
    case attendanceCheckOnly
  }

  @Dependency(\.homeUseCase) private var homeUseCase
  @Dependency(\.notificationUseCase) private var notificationUseCase
  @Dependency(\.attendanceUseCase) private var attendanceUseCase
  @Dependency(\.analyticsUseCase) private var analyticsUseCase
  @Dependency(\.date.now) private var now

  public var body: some Reducer<State, Action> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .binding:
        .none
      case let .view(viewAction):
        handleViewAction(state: &state, action: viewAction)
      case let .async(asyncAction):
        handleAsyncAction(state: &state, action: asyncAction)
      case let .inner(innerAction):
        handleInnerAction(state: &state, action: innerAction)
      case let .delegate(delegateAction):
        handleDelegateAction(state: &state, action: delegateAction)
      case let .attendanceModal(presentationAction):
        handleAttendanceModal(state: &state, action: presentationAction)
      }
    }
    .ifLet(\.$attendanceModal, action: \.attendanceModal) {
      AttendanceModalFeature()
    }
  }
}

extension HomeFeature {
  private func handleViewAction(
    state: inout State,
    action: View
  ) -> Effect<Action> {
    switch action {
    case .onAppear:
      analyticsUseCase.track(.screenView(screen: .home, referrer: nil))
      // 벨 배지는 진입/재진입마다 서버(/unread)로 갱신 — fetchHome 이 스킵돼도 stale 방지.
      let syncBadge: Effect<Action> = .send(.async(.syncUnreadBadge))
      // Android: 출석 시트는 홈 진입 시 하루 1회(세션당 한 번 시도), 체크만은 하루 1회.
      let attendance = attendanceEffectOnAppear(state: &state)
      // 홈 조회는 첫 진입 한 번만(Android ViewModel init) — 실패·로딩 중·로드 완료면 다시 부르지 않고 새로고침으로만 다시 부른다.
      // 초기값 `.loaded` + 미로드 = 한 번도 요청하지 않은 상태.
      guard !state.hasLoadedHome, state.viewState == .loaded else {
        return .merge(syncBadge, attendance)
      }
      return .merge(syncBadge, attendance, .send(.async(.fetchHome)))

    case .appBecameActive:
      let today = now.formatted(.yearMonthDay)
      guard !AttendanceDayRecord().isChecked(on: today) else { return .none }
      return .send(.async(.checkAttendanceOnly(day: today)))

    case .pullToRefresh:
      guard state.viewState != .loading else { return .none }
      return .send(.async(.refreshHome))

    case let .heroTapped(battle):
      analyticsUseCase.track(.contentAction(ContentActionData(action: .heroTap, contentID: "\(battle.battleId)")))
      return .send(.delegate(.presentPreVote(battleId: battle.battleId)))

    case let .hotBattleTapped(battle):
      analyticsUseCase.track(.contentAction(ContentActionData(
        action: .battleCardTap,
        contentID: "\(battle.battleId)",
        section: .hot
      )))
      return .send(.delegate(.presentPreVote(battleId: battle.battleId)))

    case let .bestBattleTapped(battle):
      analyticsUseCase.track(.contentAction(ContentActionData(
        action: .battleCardTap,
        contentID: "\(battle.battleId)",
        section: .best
      )))
      return .send(.delegate(.presentPreVote(battleId: battle.battleId)))

    case let .bestCommentTapped(comment):
      analyticsUseCase.track(.contentAction(ContentActionData(
        action: .battleCardTap,
        contentID: "\(comment.battleId)",
        section: .bestComment
      )))
      return .send(.delegate(.presentPreVote(battleId: comment.battleId)))

    case let .newBattleTapped(battle):
      analyticsUseCase.track(.contentAction(ContentActionData(
        action: .newBattleTap,
        contentID: "\(battle.battleId)",
        section: .new
      )))
      return .send(.delegate(.presentPreVote(battleId: battle.battleId)))

    case .notificationTapped:
      analyticsUseCase.track(.uiAction(action: .homeNotification, screen: .home))
      return .send(.delegate(.openNotification))

    case .adNativeClicked:
      analyticsUseCase.track(.adClick(AdClickData(placement: .home, format: .native, unit: "ADFIT_NATIVE_2_1")))
      return .none

    case .homeTabReselected:
      state.scrollToTopRequest += 1
      return .none

    case .toastShown:
      state.toastMessage = nil
      return .none
    }
  }

  private func handleAsyncAction(
    state: inout State,
    action: AsyncAction
  ) -> Effect<Action> {
    switch action {
    case .fetchHome:
      state.viewState = .loading
      return requestHome()

    case .refreshHome:
      return requestHome()

    case .syncUnreadBadge:
      return .run { [useCase = notificationUseCase] send in
        let result = await Result {
          try await useCase.hasUnreadNotifications()
        }
        .mapError(AuthError.from)
        await send(.inner(.unreadBadgeResponse(result)))
      }
      .cancellable(id: CancelID.syncUnreadBadge, cancelInFlight: true)

    case let .checkAttendance(day):
      return .run { [useCase = attendanceUseCase] send in
        let result = try? await useCase.checkAttendance()
        if result != nil {
          await send(.inner(.attendanceChecked(day: day)))
        }
        // Android: 체크 결과(이미 출석·실패)와 관계없이 주간 조회가 성공하면 시트를 띄운다.
        guard let weekly = try? await useCase.fetchWeeklyAttendance() else { return }
        await send(.inner(.attendanceResponse(
          day: day,
          weekly: weekly,
          pointsEarned: (result?.pointsEarned ?? 0) + (result?.streakBonusPoints ?? 0)
        )))
      }
      .cancellable(id: CancelID.attendance, cancelInFlight: true)

    case let .checkAttendanceOnly(day):
      return .run { [useCase = attendanceUseCase] send in
        guard (try? await useCase.checkAttendance()) != nil else { return }
        await send(.inner(.attendanceChecked(day: day)))
      }
      .cancellable(id: CancelID.attendanceCheckOnly, cancelInFlight: true)
    }
  }

  /// 홈 조회 요청 — 첫 조회와 새로고침이 같은 요청을 쓰고, 새 요청이 진행 중인 요청을 취소한다.
  private func requestHome() -> Effect<Action> {
    .run { [repository = homeUseCase] send in
      let result = await Result {
        try await repository.fetchHome()
      }
      .mapError(AuthError.from)
      return await send(.inner(.homeResponse(result)))
    }
    .cancellable(id: CancelID.fetchHome, cancelInFlight: true)
  }

  private func handleInnerAction(
    state: inout State,
    action: InnerAction
  ) -> Effect<Action> {
    switch action {
    case let .homeResponse(result):
      switch result {
      case let .success(bundle):
        state.viewState = .loaded
        state.hasLoadedHome = true
        let home = bundle.replacingEmptySectionsWithMocks
        state.newNotice = home.newNotice
        state.heroes = home.heroes
        state.heroIndex = 0
        state.hotBattles = home.hotBattles
        state.bestBattles = home.bestBattles
        state.bestComments = home.bestComments
        state.newBattles = home.newBattles
      case let .failure(error):
        state.viewState = .failed
        state.toastMessage = "정보를 불러오지 못했어요"
        PickeLogger.error("[HomeFeature] fetchHome failed: \(error.localizedDescription)", category: .ui)
      }
      return .none

    case let .unreadBadgeResponse(result):
      state.isUnreadBadgeLoading = false
      // 서버(/unread) 값을 그대로 반영 — 실패하면 기존 배지를 그대로 둔다(Android 와 동일).
      if case let .success(hasUnread) = result {
        state.hasUnreadNotification = hasUnread
      }
      return .none

    case let .attendanceChecked(day):
      AttendanceDayRecord().markChecked(on: day)
      return .none

    case let .attendanceResponse(day, weekly, pointsEarned):
      AttendanceDayRecord().markSheetShown(on: day)
      var modalState = AttendanceModalFeature.State()
      modalState.weekly = weekly
      modalState.pointsEarned = pointsEarned
      state.attendanceModal = modalState
      return .none
    }
  }

  /// 홈 진입 시 출석 처리 — 오늘 시트를 아직 안 보였으면 체크+시트, 보였는데 체크가 안 됐으면 체크만.
  private func attendanceEffectOnAppear(state: inout State) -> Effect<Action> {
    guard !state.hasTriedAttendance else { return .none }
    state.hasTriedAttendance = true
    let today = now.formatted(.yearMonthDay)
    let record = AttendanceDayRecord()
    if !record.isSheetShown(on: today) {
      return .send(.async(.checkAttendance(day: today)))
    }
    if !record.isChecked(on: today) {
      return .send(.async(.checkAttendanceOnly(day: today)))
    }
    return .none
  }

  private func handleAttendanceModal(
    state: inout State,
    action: PresentationAction<AttendanceModalFeature.Action>
  ) -> Effect<Action> {
    switch action {
    case .presented(.delegate(.dismissed)), .dismiss:
      state.attendanceModal = nil
      return .none

    case .presented:
      return .none
    }
  }

  private func handleDelegateAction(
    state _: inout State,
    action: HomeDelegate
  ) -> Effect<Action> {
    switch action {
    case .presentPreVote, .openNotification:
      return .none
    }
  }
}
