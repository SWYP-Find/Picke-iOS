//
//  PreVoteFeature.swift
//  Home
//
//  Created by Wonji Suh on 5/16/26.
//

import Foundation

import ComposableArchitecture
import DomainInterface
import Entity
import LogMacro

@Reducer
public struct PreVoteFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public var battle: PreVoteBattle = .mock
    public var poll: PollDetail?
    public var selectedSide: PhilosopherAvatar?
    public var isLoading: Bool = false
    public var isSubmitting: Bool = false
    public var shareItem: ShareItem?
    public var pollId: Int = 1

    public var isPrimaryButtonEnabled: Bool {
      selectedSide != nil && !isSubmitting
    }

    public init() {}
  }

  /// 공유 시트 트리거. `.sheet(item:)` 에 바로 바인딩.
  public struct ShareItem: Equatable, Identifiable {
    public let id: UUID
    public let items: [String]

    public init(id: UUID = UUID(), items: [String]) {
      self.id = id
      self.items = items
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
    case backButtonTapped
    case shareTapped
    case optionTapped(PhilosopherAvatar)
    case primaryButtonTapped
  }

  public enum AsyncAction: Equatable {
    case fetchPoll
  }

  public enum InnerAction: Equatable {
    case pollResponse(Result<PollDetail, AuthError>)
  }

  public enum DelegateAction: Equatable {
    case dismiss
    case submit(pollId: Int, side: PhilosopherAvatar)
  }

  nonisolated enum CancelID: Hashable {
    case fetchPoll
  }

  @Dependency(\.pollRepository) private var pollRepository

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

extension PreVoteFeature {
  private func handleViewAction(
    state: inout State,
    action: View
  ) -> Effect<Action> {
    switch action {
    case .onAppear:
      guard state.poll == nil, !state.isLoading else { return .none }
      return .send(.async(.fetchPoll))

    case .backButtonTapped:
      return .send(.delegate(.dismiss))

    case .shareTapped:
      let title = state.poll.map { "\($0.titlePrefix) \($0.titleSuffix)" }
        ?? "\(state.battle.titleLine1) \(state.battle.titleLine2)"
      state.shareItem = ShareItem(
        items: [
          title,
          "https://picke.store/poll/\(state.pollId)",
        ]
      )
      return .none

    case let .optionTapped(side):
      state.selectedSide = (state.selectedSide == side) ? nil : side
      return .none

    case .primaryButtonTapped:
      guard let side = state.selectedSide else { return .none }
      state.isSubmitting = true
      return .send(.delegate(.submit(pollId: state.pollId, side: side)))
    }
  }

  private func handleAsyncAction(
    state: inout State,
    action: AsyncAction
  ) -> Effect<Action> {
    switch action {
    case .fetchPoll:
      state.isLoading = true
      let pollId = state.pollId
      return .run { [repository = pollRepository] send in
        let result = await Result {
          try await repository.fetchPoll(pollId: pollId)
        }
        .mapError(AuthError.from)
        return await send(.inner(.pollResponse(result)))
      }
      .cancellable(id: CancelID.fetchPoll, cancelInFlight: true)
    }
  }

  private func handleInnerAction(
    state: inout State,
    action: InnerAction
  ) -> Effect<Action> {
    switch action {
    case let .pollResponse(result):
      state.isLoading = false
      switch result {
      case let .success(poll):
        state.poll = poll
        state.battle = makeBattle(from: poll, fallback: state.battle)
      case let .failure(error):
        Log.error("[PreVoteFeature] fetchPoll failed: \(error.localizedDescription)")
      }
      return .none
    }
  }

  /// API 로 받은 PollDetail 을 화면 모델 PreVoteBattle 로 매핑.
  /// background/summary/tags 는 응답에 없으므로 fallback (이전 state.battle) 값을 유지한다.
  /// 옵션은 displayOrder 순으로 앞에서부터 2개만 좌/우 카드에 매핑.
  private func makeBattle(
    from poll: PollDetail,
    fallback: PreVoteBattle
  ) -> PreVoteBattle {
    let philosophers: [PhilosopherAvatar] = [.plato, .sartre, .sunja]
    let mapped = poll.options.enumerated().map { idx, option in
      PreVoteOption(
        philosopher: philosophers[safe: idx] ?? .plato,
        stance: option.title
      )
    }
    let leftOption = mapped[safe: 0] ?? fallback.leftOption
    let rightOption = mapped[safe: 1] ?? fallback.rightOption

    return PreVoteBattle(
      battleId: poll.pollId,
      backgroundImageURL: fallback.backgroundImageURL,
      tags: fallback.tags,
      titleLine1: poll.titlePrefix,
      titleLine2: poll.titleSuffix,
      summary: fallback.summary,
      leftOption: leftOption,
      rightOption: rightOption
    )
  }

  private func handleDelegateAction(
    state _: inout State,
    action: DelegateAction
  ) -> Effect<Action> {
    switch action {
    case .dismiss, .submit:
      .none
    }
  }
}

private extension Array {
  subscript(safe index: Int) -> Element? {
    indices.contains(index) ? self[index] : nil
  }
}
