//
//  PointHistoryFeature.swift
//  Profile
//

import Foundation
import ProfileDomainInterface

import ComposableArchitecture
import Entity
import LogMacro
import PickeDesignKit
import UseCase

@Reducer
public struct PointHistoryFeature {
  public init() {}

  static let pageSize = 20

  @ObservableState
  public struct State: Equatable {
    public var isLoading: Bool = false
    public var isLoadingMore: Bool = false
    public var items: [CreditHistoryItem] = []
    public var nextOffset: Int = 0
    public var hasNext: Bool = false
    @Presents public var customAlert: CustomAlertState<CustomAlertAction>?

    public init() {}
  }

  public enum Action: ViewAction, BindableAction {
    case binding(BindingAction<State>)
    case view(View)
    case async(AsyncAction)
    case inner(InnerAction)
    case scope(ScopeAction)
    case delegate(DelegateAction)
  }

  @CasePathable
  public enum View {
    case onAppear
    case backTapped
    case reachedBottom
    case suggestTopicTapped
  }

  public enum AsyncAction: Equatable {
    case fetch(reset: Bool)
  }

  public enum InnerAction: Equatable {
    case historyResponse(Result<CreditHistoryPage, ProfileError>, reset: Bool)
  }

  @CasePathable
  public enum ScopeAction: Equatable {
    case customAlert(PresentationAction<CustomAlertAction>)
  }

  public enum DelegateAction: Equatable {
    case dismiss
    /// 주제(배틀) 제안 화면 진입.
    case suggestTopic
  }

  nonisolated enum CancelID: Hashable {
    case fetch
  }

  @Dependency(\.profileUseCase) private var profileUseCase

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

      case let .scope(scopeAction):
        return handleScopeAction(state: &state, action: scopeAction)

      case let .delegate(delegateAction):
        return handleDelegateAction(state: &state, action: delegateAction)
      }
    }
    .ifLet(\.$customAlert, action: \.scope.customAlert) {
      CustomConfirmAlert()
    }
  }
}

extension PointHistoryFeature {
  private func handleViewAction(
    state: inout State,
    action: View
  ) -> Effect<Action> {
    switch action {
    case .onAppear:
      guard state.items.isEmpty else { return .none }
      return .send(.async(.fetch(reset: true)))

    case .backTapped:
      return .send(.delegate(.dismiss))

    case .reachedBottom:
      guard state.hasNext, !state.isLoadingMore, !state.isLoading else { return .none }
      return .send(.async(.fetch(reset: false)))

    case .suggestTopicTapped:
      state.customAlert = .suggestTopic()
      return .none
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
      let offset: Int? = reset ? nil : state.nextOffset
      return .run { [useCase = profileUseCase] send in
        let result = await Result {
          try await useCase.fetchCreditHistory(offset: offset, size: Self.pageSize)
        }
        .mapError(ProfileError.from)
        return await send(.inner(.historyResponse(result, reset: reset)))
      }
      .cancellable(id: CancelID.fetch, cancelInFlight: reset)
    }
  }

  private func handleInnerAction(
    state: inout State,
    action: InnerAction
  ) -> Effect<Action> {
    switch action {
    case let .historyResponse(result, reset):
      state.isLoading = false
      state.isLoadingMore = false
      switch result {
      case let .success(page):
        if reset {
          state.items = page.items
        } else {
          state.items.append(contentsOf: page.items)
        }
        state.nextOffset = page.nextOffset
        state.hasNext = page.hasNext
      case let .failure(error):
        Log.error("[PointHistoryFeature] fetchCreditHistory failed: \(error.localizedDescription)")
      }
      return .none
    }
  }

  private func handleScopeAction(
    state: inout State,
    action: ScopeAction
  ) -> Effect<Action> {
    switch action {
    case let .customAlert(alertAction):
      switch alertAction {
      case let .presented(customAlertAction):
        switch customAlertAction {
        case .confirmTapped:
          // 제안하기 → 주제 제안 화면 진입 (추후 연동).
          state.customAlert = nil
          return .send(.delegate(.suggestTopic))
        case .cancelTapped:
          state.customAlert = nil
          return .none
        }
      case .dismiss:
        state.customAlert = nil
        return .none
      }
    }
  }

  private func handleDelegateAction(
    state _: inout State,
    action: DelegateAction
  ) -> Effect<Action> {
    switch action {
    case .dismiss:
      return .none
    case .suggestTopic:
      return .none
    }
  }
}
