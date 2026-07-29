//
//  BattleFeature.swift
//  Battle
//

import Foundation

import ComposableArchitecture
import Entity
import BattleDomainInterface
import LogMacro
import UseCase

@Reducer
public struct BattleFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public var isLoading: Bool = false
    /// 오늘의 배틀 목록 — 세로 스크롤로 다음 배틀 노출. 비어있으면 "없음".
    public var battles: [DailyBattle] = []
    /// 배틀별 선택한 옵션 (battleId → optionId). 미선택 시 "배틀 입장하기" 비활성.
    public var selectedOptionByBattle: [Int: Int] = [:]
    /// 이미 입장(투표)한 배틀 — 복귀 시 옵션 변경 비활성화.
    public var votedBattleIds: Set<Int> = []
    /// 시스템 공유 시트 트리거.
    public var shareItem: ShareItem?

    public init() {}

    public func selectedOption(for battleId: Int) -> Int? {
      selectedOptionByBattle[battleId]
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
  }

  public enum AsyncAction: Equatable {
    case fetchRequested
  }

  public enum InnerAction: Equatable {
    case todayResponse(Result<TodayBattlePage, BattleError>)
  }

  nonisolated enum CancelID: Hashable {
    case fetchToday
  }

  @Dependency(\.battleUseCase) private var battleUseCase
  @Dependency(\.analyticsUseCase) private var analyticsUseCase

  public enum DelegateAction: Equatable {
    /// 배틀 입장 → 채팅방 진입
    case openBattle(battleId: Int)
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
      let text = [
        battle.title,
        battle.question,
        battle.tags.map { "#\($0)" }.joined(separator: " "),
      ]
      .filter { !$0.isEmpty }
      .joined(separator: "\n\n")
      var items: [Any] = [text]
      if let urlString = battle.imageURL, let url = URL(string: urlString) { items.append(url) }
      state.shareItem = ShareItem(items: items)
      return .none

    case let .optionTapped(battleId, optionId):
      analyticsUseCase.track(.uiAction(action: .quickBattleOption, screen: .quickBattle))
      // 같은 옵션 재탭 시 해제, 아니면 선택.
      if state.selectedOptionByBattle[battleId] == optionId {
        state.selectedOptionByBattle[battleId] = nil
      } else {
        state.selectedOptionByBattle[battleId] = optionId
      }
      return .none

    case let .enterBattleTapped(battleId):
      analyticsUseCase.track(.uiAction(action: .quickBattleEnter, screen: .quickBattle))
      // 선택해야만 입장 가능. 입장 시 투표 확정 → 복귀 시 옵션 변경 비활성화.
      guard state.selectedOptionByBattle[battleId] != nil else { return .none }
      state.votedBattleIds.insert(battleId)
      return .send(.delegate(.openBattle(battleId: battleId)))
    }
  }

  private func handleAsyncAction(
    state: inout State,
    action: AsyncAction
  ) -> Effect<Action> {
    switch action {
    case .fetchRequested:
      state.isLoading = true
      return .run { [useCase = battleUseCase] send in
        let result = await Result {
          try await useCase.fetchTodayBattles()
        }
        .mapError(BattleError.from)
        return await send(.inner(.todayResponse(result)))
      }
      .cancellable(id: CancelID.fetchToday, cancelInFlight: true)
    }
  }

  private func handleInnerAction(
    state: inout State,
    action: InnerAction
  ) -> Effect<Action> {
    switch action {
    case let .todayResponse(result):
      state.isLoading = false
      switch result {
      case let .success(page):
        state.battles = page.items.map(DailyBattle.from)
      case let .failure(error):
        state.battles = []
        Log.error("[BattleFeature] fetchTodayBattles failed: \(error.localizedDescription)")
      }
      return .none
    }
  }
}
