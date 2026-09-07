//
//  NotificationSettingFeature.swift
//  Profile
//

import Foundation
import ProfileDomainInterface

import ComposableArchitecture

@Reducer
public struct NotificationSettingFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public var isLoading: Bool = false
    public var settings: NotificationSettings = .init()

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
    case toggle(NotificationSettingKey)
  }

  public enum AsyncAction: Equatable {
    case fetch
    case update(NotificationSettings)
  }

  public enum InnerAction: Equatable {
    case settingsResponse(Result<NotificationSettings, ProfileError>)
  }

  public enum DelegateAction: Equatable {
    case dismiss
  }

  nonisolated enum CancelID: Hashable {
    case fetch
    case update
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

extension NotificationSettingFeature {
  private func handleViewAction(
    state: inout State,
    action: View
  ) -> Effect<Action> {
    switch action {
    case .onAppear:
      return .send(.async(.fetch))

    case .backTapped:
      return .send(.delegate(.dismiss))

    case let .toggle(key):
      // 낙관적 갱신 후 PATCH.
      let updated = state.settings.setting(key, to: !state.settings.isOn(key))
      state.settings = updated
      return .send(.async(.update(updated)))
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
          try await useCase.fetchNotificationSettings()
        }
        .mapError(ProfileError.from)
        return await send(.inner(.settingsResponse(result)))
      }
      .cancellable(id: CancelID.fetch, cancelInFlight: true)

    case let .update(settings):
      return .run { [useCase = profileUseCase] send in
        let result = await Result {
          try await useCase.updateNotificationSettings(settings)
        }
        .mapError(ProfileError.from)
        return await send(.inner(.settingsResponse(result)))
      }
      .cancellable(id: CancelID.update, cancelInFlight: true)
    }
  }

  private func handleInnerAction(
    state: inout State,
    action: InnerAction
  ) -> Effect<Action> {
    switch action {
    case let .settingsResponse(result):
      state.isLoading = false
      switch result {
      case let .success(settings):
        state.settings = settings
      case let .failure(error):
        Log.error("[NotificationSettingFeature] settings request failed: \(error.localizedDescription)")
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
    }
  }
}
