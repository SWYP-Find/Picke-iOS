//
//  RecapFeature.swift
//  Profile
//
//  나의 철학자 유형(리캡) — picke.pen `나의 철학자 유형`.
//  GET /api/v1/me/recap 로드 + 공유.
//

import Foundation

import ComposableArchitecture
import Entity
import LogMacro
import UseCase

@Reducer
public struct RecapFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public var isLoading: Bool = false
    public var recap: PhilosopherRecap?
    /// 애플 시스템 공유 시트 트리거.
    public var shareItem: ShareItem?

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
    case shareTapped
  }

  public enum AsyncAction: Equatable {
    case fetch
  }

  public enum InnerAction: Equatable {
    case recapResponse(Result<PhilosopherRecap, ProfileError>)
  }

  public enum DelegateAction: Equatable {
    case dismiss
    case share(PhilosopherRecap)
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

      case let .delegate(delegateAction):
        return handleDelegateAction(state: &state, action: delegateAction)
      }
    }
  }
}

extension RecapFeature {
  private func handleViewAction(
    state: inout State,
    action: View
  ) -> Effect<Action> {
    switch action {
    case .onAppear:
      guard state.recap == nil else { return .none }
      return .send(.async(.fetch))

    case .backTapped:
      return .send(.delegate(.dismiss))

    case .shareTapped:
      guard let recap = state.recap else { return .none }
      let text = [
        "나의 철학자 유형: \(recap.myCard.typeName)",
        recap.myCard.description,
        recap.myCard.keywordTags.map { "#\($0)" }.joined(separator: " "),
      ]
      .filter { !$0.isEmpty }
      .joined(separator: "\n\n")
      var items: [Any] = [text]
      if !recap.myCard.imageURL.isEmpty, let url = URL(string: recap.myCard.imageURL) {
        items.append(url)
      }
      state.shareItem = ShareItem(items: items)
      return .none
    }
  }

  private func handleAsyncAction(
    state: inout State,
    action: AsyncAction
  ) -> Effect<Action> {
    switch action {
    case .fetch:
      state.isLoading = true
      return .run { [useCase = profileUseCase] send in
        let result = await Result {
          try await useCase.fetchRecap()
        }
        .mapError(ProfileError.from)
        return await send(.inner(.recapResponse(result)))
      }
      .cancellable(id: CancelID.fetch, cancelInFlight: true)
    }
  }

  private func handleInnerAction(
    state: inout State,
    action: InnerAction
  ) -> Effect<Action> {
    switch action {
    case let .recapResponse(result):
      state.isLoading = false
      switch result {
      case let .success(recap):
        state.recap = recap
      case let .failure(error):
        Log.error("[RecapFeature] fetchRecap failed: \(error.localizedDescription)")
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
    case .share:
      return .none
    }
  }
}
