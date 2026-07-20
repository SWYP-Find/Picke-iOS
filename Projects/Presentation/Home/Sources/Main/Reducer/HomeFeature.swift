//
//  HomeFeature.swift
//  Home
//
//  Created by Wonji Suh on 5/15/26.
//

import AttendanceDomainInterface
import ComposableArchitecture
import DomainInterface
import Entity
import Foundation
import HomeDomainInterface
import HomeInterface
import LogMacro
import NotificationDomainInterface
import Shared
import UseCase

@Reducer
public struct HomeFeature {
  public init() {}

  /// 출석체크 결과 시트에 넘길 표시용 데이터.
  /// 시트 자체는 상호작용이 없어 자식 리듀서를 두지 않고 값만 들고 있다가 `.sheet(item:)` 으로 띄운다.
  public struct AttendanceSheetData: Equatable, Identifiable {
    public let weekly: WeeklyAttendance
    public let pointsEarned: Int

    public var id: String { weekly.weekStartDate }

    public init(weekly: WeeklyAttendance, pointsEarned: Int) {
      self.weekly = weekly
      self.pointsEarned = pointsEarned
    }
  }

  @ObservableState
  public struct State: Equatable {
    public var isLoading: Bool = false
    public var hasLoadedHome: Bool = false
    public var newNotice: Bool = false
    public var heroes: [HeroBattle] = []
    public var heroIndex: Int = 0
    public var hotBattles: [HotBattle] = []
    public var bestBattles: [BestBattle] = []
    public var quizzes: [QuizQuestion] = []
    public var votes: [VoteQuestion] = []
    public var newBattles: [NewBattle] = []

    /// 종 아이콘 빨간점 — 미읽음 알림 존재 여부. 화면 진입마다 /unread 서버값으로 갱신(저장 안 함).
    public var hasUnreadNotification: Bool = false

    /// 출석체크 시트 — 오늘 첫 출석에 성공했을 때만 값이 찬다.
    public var attendanceSheet: AttendanceSheetData?
    /// 출석 체크는 앱 세션당 1회만 시도한다(하루 1회 제한이라 재진입마다 때릴 이유가 없다).
    public var hasTriedAttendance: Bool = false

    public var currentQuiz: QuizQuestion? { quizzes.first }
    public var currentVote: VoteQuestion? { votes.first }

    public init() {}
  }

  public enum Action: ViewAction, BindableAction {
    case binding(BindingAction<State>)
    case view(View)
    case async(AsyncAction)
    case inner(InnerAction)
    case delegate(HomeDelegate)
  }

  @CasePathable
  public enum View {
    case onAppear
    case pullToRefresh
    case seeMoreTapped(Section)
    case voteTapped(VoteQuestion)
    case heroTapped(HeroBattle)
    case hotBattleTapped(HotBattle)
    case bestBattleTapped(BestBattle)
    case newBattleTapped(NewBattle)
    case notificationTapped
  }

  public enum Section: Equatable {
    case hotBattles
    case bestBattles
    case todayPicke
    case newBattles
  }

  public enum AsyncAction: Equatable {
    case fetchHome
    /// 벨 배지용 미읽음 여부 서버 동기화 (GET /api/v1/notifications/unread).
    case syncUnreadBadge
    /// 오늘의 출석 체크 (POST /attendance/check) — 성공 시 주간 현황까지 이어 조회한다.
    case checkAttendance
  }

  public enum InnerAction: Equatable {
    case homeResponse(Result<HomeBundle, AuthError>)
    case unreadBadgeResponse(Bool)
    /// 출석 체크 성공 + 주간 현황 조회까지 끝난 결과.
    case attendanceResponse(weekly: WeeklyAttendance, pointsEarned: Int)
  }

  nonisolated enum CancelID: Hashable {
    case fetchHome
    case syncUnreadBadge
    case attendance
  }

  @Dependency(\.homeUseCase) private var homeUseCase
  @Dependency(\.notificationUseCase) private var notificationUseCase
  @Dependency(\.attendanceUseCase) private var attendanceUseCase
  @Dependency(\.analyticsUseCase) private var analyticsUseCase

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
      }
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
      // 출석 체크는 세션당 1회 — 하루 1회 제한이라 재진입마다 호출할 이유가 없다.
      let attendance: Effect<Action> = state.hasTriedAttendance
        ? .none
        : .send(.async(.checkAttendance))
      state.hasTriedAttendance = true
      guard !state.hasLoadedHome, !state.isLoading else {
        return .merge(syncBadge, attendance)
      }
      return .merge(syncBadge, attendance, .send(.async(.fetchHome)))

    case .pullToRefresh:
      guard !state.isLoading else { return .none }
      return .send(.async(.fetchHome))

    case .seeMoreTapped:
      analyticsUseCase.track(.uiAction(action: .homeMore, screen: .home))
      return .send(.delegate(.moveToExplore))

    case let .voteTapped(question):
      analyticsUseCase.track(.contentAction(ContentActionData(
        action: .voteCardTap,
        contentID: "\(question.battleId)",
        section: .vote
      )))
      return .send(.delegate(.presentPreVote(battleId: question.battleId)))

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
    }
  }

  private func handleAsyncAction(
    state: inout State,
    action: AsyncAction
  ) -> Effect<Action> {
    switch action {
    case .fetchHome:
      state.isLoading = true
      return .run { [repository = homeUseCase] send in
        let result = await Result {
          try await repository.fetchHome()
        }
        .mapError(AuthError.from)
        return await send(.inner(.homeResponse(result)))
      }
      .cancellable(id: CancelID.fetchHome, cancelInFlight: true)

    case .syncUnreadBadge:
      return .run { [useCase = notificationUseCase] send in
        guard let hasUnread = try? await useCase.hasUnreadNotifications() else { return }
        await send(.inner(.unreadBadgeResponse(hasUnread)))
      }
      .cancellable(id: CancelID.syncUnreadBadge, cancelInFlight: true)

    case .checkAttendance:
      return .run { [useCase = attendanceUseCase] send in
        // 이미 오늘 출석했으면 서버가 거절한다 — 그 경우 시트를 띄우지 않고 조용히 끝낸다.
        guard let result = try? await useCase.checkAttendance() else { return }
        guard let weekly = try? await useCase.fetchWeeklyAttendance() else { return }
        await send(.inner(.attendanceResponse(
          weekly: weekly,
          pointsEarned: result.pointsEarned + result.streakBonusPoints
        )))
      }
      .cancellable(id: CancelID.attendance, cancelInFlight: true)
    }
  }

  private func handleInnerAction(
    state: inout State,
    action: InnerAction
  ) -> Effect<Action> {
    switch action {
    case let .homeResponse(result):
      state.isLoading = false
      state.hasLoadedHome = true
      switch result {
      case let .success(bundle):
        let home = bundle.replacingEmptySectionsWithMocks
        state.newNotice = home.newNotice
        state.heroes = home.heroes
        state.heroIndex = 0
        state.hotBattles = home.hotBattles
        state.bestBattles = home.bestBattles
        state.quizzes = home.quizzes
        state.votes = home.votes
        state.newBattles = home.newBattles
      case let .failure(error):
        Log.error("[HomeFeature] fetchHome failed: \(error.localizedDescription)")
      }
      return .none

    case let .unreadBadgeResponse(hasUnread):
      // 서버(/unread) 값을 그대로 반영 — 별도 저장/가드 없이 진입 시점 진실값만 사용.
      state.hasUnreadNotification = hasUnread
      return .none

    case let .attendanceResponse(weekly, pointsEarned):
      state.attendanceSheet = AttendanceSheetData(weekly: weekly, pointsEarned: pointsEarned)
      return .none
    }
  }

  private func handleDelegateAction(
    state _: inout State,
    action: HomeDelegate
  ) -> Effect<Action> {
    switch action {
    case .presentPreVote, .moveToExplore, .openNotification:
      return .none
    }
  }
}
