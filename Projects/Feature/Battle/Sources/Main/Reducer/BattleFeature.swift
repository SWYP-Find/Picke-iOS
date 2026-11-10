//
//  BattleFeature.swift
//  Battle
//
//  Created by Picke on 10/11/26.
//

import Foundation
import PickeCoreLogger

import BattleDomainInterface
import ComposableArchitecture
import PickeAnalyticsInterface
import PickeCoreUtility

@Reducer
public struct BattleFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    /// 화면이 스켈레톤을 보일지 콘텐츠를 보일지 가르는 상태.
    public enum ViewState: Equatable {
      case loading
      case loaded
    }

    public var viewState: ViewState = .loaded
    /// 오늘의 배틀 목록 — 세로 스크롤로 다음 배틀 노출. 비어있으면 "없음".
    public var battles: [DailyBattle] = []
    /// 배틀별 선택한 옵션 (battleId → optionId). 미선택 시 "배틀 입장하기" 비활성.
    public var selectedOptionByBattle: [Int: Int] = [:]
    /// 이미 입장(투표)한 배틀 — 복귀 시 옵션 변경 비활성화.
    public var votedBattleIds: Set<Int> = []
    /// 시스템 공유 시트 트리거.
    public var shareItem: ShareItem?
    /// Android `isEntering` — 입장 요청 중에는 버튼을 막는다.
    public var isEntering: Bool = false
    /// Android 불러오기 실패 토스트 문구. 보여준 뒤 `toastShown` 으로 비운다.
    public var toastMessage: String?

    public init() {}

    public func selectedOption(for battleId: Int) -> Int? {
      selectedOptionByBattle[battleId]
    }

    public func isEnterEnabled(for battleId: Int) -> Bool {
      selectedOptionByBattle[battleId] != nil && !isEntering
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
    case shareTapped(battleId: Int)
    case optionTapped(battleId: Int, optionId: Int)
    case enterBattleTapped(battleId: Int)
    case pagingTapped(index: Int)
    case toastShown
  }

  public enum AsyncAction: Equatable {
    case fetchRequested
    case prepareShare(ShareContent)
    case checkEntryStep(battleId: Int, optionId: Int)
    case submitPreVote(battleId: Int, optionId: Int)
  }

  public enum InnerAction: Equatable {
    case todayResponse(Result<TodayBattlePage, BattleError>)
    case sharePrepared(ShareItem)
    case entryStepResponse(battleId: Int, optionId: Int, Result<BattleStep, BattleError>)
    case preVoteResponse(battleId: Int, Result<PreVoteResult, BattleError>)
  }

  nonisolated enum CancelID: Hashable {
    case fetchToday
    case enter
  }

  @Dependency(\.battleUseCase) private var battleUseCase
  @Dependency(\.analyticsUseCase) private var analyticsUseCase
  @Dependency(\.shareUseCase) private var shareUseCase

  public enum DelegateAction: Equatable {
    /// 배틀 입장(사전투표 완료) → 채팅방 진입
    case openBattle(battleId: Int)
    /// 이미 참여한 배틀 → 관점(댓글) 화면 진입
    case openPerspective(battleId: Int)
    /// 상단 백탭 → 홈 탭으로 복귀
    case backToHome
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

      case .delegate:
        return .none
      }
    }
  }
}

extension BattleFeature {
  private func handleViewAction(
    state: inout State,
    action: View
  ) -> Effect<Action> {
    switch action {
    case .onAppear:
      analyticsUseCase.track(.screenView(screen: .quickBattle, referrer: nil))
      return .send(.async(.fetchRequested))

    case let .pagingTapped(index):
      let contentID = state.battles.indices.contains(index) ? "\(state.battles[index].id)" : nil
      analyticsUseCase.track(.contentAction(ContentActionData(action: .quickBattleNext, contentID: contentID)))
      return .none

    case .backTapped:
      analyticsUseCase.track(.uiAction(action: .quickBattleBack, screen: .quickBattle))
      return .send(.delegate(.backToHome))

    case let .shareTapped(battleId):
      analyticsUseCase.track(.shareAction(ShareActionData(target: .battle)))
      guard let battle = state.battles.first(where: { $0.battleId == battleId }) else { return .none }
      let content = ShareContent(
        title: battle.title,
        summary: battle.question,
        hashtags: battle.tags.map { "#\($0)" },
        optionLine: nil,
        url: PickeShareURL.battle(id: battleId),
        thumbnailURL: battle.imageURL,
        snapshotData: nil
      )
      return .send(.async(.prepareShare(content)))

    case let .optionTapped(battleId, optionId):
      analyticsUseCase.track(.uiAction(action: .quickBattleOption, screen: .quickBattle))
      // Android 는 같은 카드를 다시 눌러도 선택을 유지한다.
      state.selectedOptionByBattle[battleId] = optionId
      return .none

    case .toastShown:
      state.toastMessage = nil
      return .none

    case let .enterBattleTapped(battleId):
      analyticsUseCase.track(.uiAction(action: .quickBattleEnter, screen: .quickBattle))
      // Android `enterBattle` — 배틀 단계를 확인해 처음이면 선택한 옵션으로 사전투표를 낸 뒤 입장한다.
      guard state.isEnterEnabled(for: battleId),
            let optionId = state.selectedOptionByBattle[battleId]
      else { return .none }
      state.isEntering = true
      return .send(.async(.checkEntryStep(battleId: battleId, optionId: optionId)))
    }
  }

  private func handleAsyncAction(
    state: inout State,
    action: AsyncAction
  ) -> Effect<Action> {
    switch action {
    case .fetchRequested:
      state.viewState = .loading
      return .run { [useCase = battleUseCase] send in
        let result = await Result {
          try await useCase.fetchTodayBattles()
        }
        .mapError(BattleError.from)
        return await send(.inner(.todayResponse(result)))
      }
      .cancellable(id: CancelID.fetchToday, cancelInFlight: true)

    case let .prepareShare(content):
      return .run { [useCase = shareUseCase] send in
        await send(.inner(.sharePrepared(useCase.makeShareItem(content))))
      }

    case let .checkEntryStep(battleId, optionId):
      return .run { [useCase = battleUseCase] send in
        let result = await Result {
          try await useCase.fetchBattle(battleId: battleId).currentStep
        }
        .mapError(BattleError.from)
        return await send(.inner(.entryStepResponse(battleId: battleId, optionId: optionId, result)))
      }
      .cancellable(id: CancelID.enter, cancelInFlight: true)

    case let .submitPreVote(battleId, optionId):
      return .run { [useCase = battleUseCase] send in
        let result = await Result {
          try await useCase.submitPreVote(battleId: battleId, optionId: optionId)
        }
        .mapError(BattleError.from)
        return await send(.inner(.preVoteResponse(battleId: battleId, result)))
      }
      .cancellable(id: CancelID.enter, cancelInFlight: true)
    }
  }

  private func handleInnerAction(
    state: inout State,
    action: InnerAction
  ) -> Effect<Action> {
    switch action {
    case let .todayResponse(result):
      state.viewState = .loaded
      switch result {
      case let .success(page):
        // Android `items.take(1)` — 첫 배틀 하나만 보인다.
        state.battles = page.items.prefix(1).map(DailyBattle.from)
      case let .failure(error):
        state.battles = []
        state.toastMessage = "정보를 불러오지 못했어요"
        PickeLogger.error("[BattleFeature] fetchTodayBattles failed: \(error.localizedDescription)", category: .ui)
      }
      return .none

    case let .sharePrepared(item):
      state.shareItem = item
      return .none

    case let .entryStepResponse(battleId, optionId, result):
      // Android: 단계가 NONE 이거나 조회에 실패하면 사전투표, 그 밖에는 관점 화면으로 간다.
      if case let .success(step) = result, step != .none {
        state.isEntering = false
        return .send(.delegate(.openPerspective(battleId: battleId)))
      }
      return .send(.async(.submitPreVote(battleId: battleId, optionId: optionId)))

    case let .preVoteResponse(battleId, result):
      state.isEntering = false
      switch result {
      case .success:
        analyticsUseCase.track(
          .battleStep(BattleStepData(stepName: .preVote, contentID: "\(battleId)"))
        )
        state.votedBattleIds.insert(battleId)
        return .send(.delegate(.openBattle(battleId: battleId)))
      case .failure(.insufficientPoints):
        state.toastMessage = "포인트가 부족합니다."
        return .none
      case let .failure(error):
        PickeLogger.error("[BattleFeature] submitPreVote failed: \(error.localizedDescription)", category: .ui)
        state.toastMessage = "요청을 처리하지 못했어요"
        return .none
      }
    }
  }
}
