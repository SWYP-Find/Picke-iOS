//
//  ContentActivityFeature.swift
//  Profile
//
//  내 콘텐츠 활동 — picke.pen `내 콘텐츠활동_댓글/좋아요`.
//  내 댓글 / 좋아요 탭, GET /api/v1/me/content-activities (offset 페이지네이션).
//

import Foundation
import ProfileDomainInterface

import ComposableArchitecture
import Entity
import LogMacro
import UseCase

@Reducer
public struct ContentActivityFeature {
  public init() {}

  static let pageSize = 20

  @ObservableState
  public struct State: Equatable {
    public var selectedTab: ContentActivityType = .comment
    public var isLoading: Bool = false
    public var isLoadingMore: Bool = false
    public var items: [ContentActivity] = []
    public var nextOffset: Int = 0
    public var hasNext: Bool = false

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
    case tabSelected(ContentActivityType)
    case reachedBottom
  }

  public enum AsyncAction: Equatable {
    case fetch(reset: Bool)
  }

  public enum InnerAction: Equatable {
    case activitiesResponse(Result<ContentActivityPage, ProfileError>, reset: Bool)
  }

  public enum DelegateAction: Equatable {
    case dismiss
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

extension ContentActivityFeature {
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

    case let .tabSelected(tab):
      guard tab != state.selectedTab else { return .none }
      state.selectedTab = tab
      state.items = []
      state.nextOffset = 0
      state.hasNext = false
      return .send(.async(.fetch(reset: true)))

    case .reachedBottom:
      guard state.hasNext, !state.isLoadingMore, !state.isLoading else { return .none }
      return .send(.async(.fetch(reset: false)))
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
      let offset = reset ? 0 : state.nextOffset
      let activityType = state.selectedTab
      return .run { [useCase = profileUseCase] send in
        let result = await Result {
          try await useCase.fetchContentActivities(
            offset: offset,
            size: Self.pageSize,
            activityType: activityType
          )
        }
        .mapError(ProfileError.from)
        return await send(.inner(.activitiesResponse(result, reset: reset)))
      }
      .cancellable(id: CancelID.fetch, cancelInFlight: true)
    }
  }

  private func handleInnerAction(
    state: inout State,
    action: InnerAction
  ) -> Effect<Action> {
    switch action {
    case let .activitiesResponse(result, reset):
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
        Log.error("[ContentActivityFeature] fetchContentActivities failed: \(error.localizedDescription)")
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
