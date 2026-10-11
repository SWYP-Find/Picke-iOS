//
//  ClassReportFeature.swift
//  Class
//
//  Created by Picke on 10/11/26.
//

import ClassDomainInterface
import ComposableArchitecture
import Foundation

@Reducer
public struct ClassReportFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public let instanceID: UUID
    public var room: ClassRoom
    public var report: ClassReport?
    public var selectedTab: ClassReportTab = .summary
    public var showsMyOpinions = false
    public var hasLoaded = false
    public var isLoading = false
    public var loadFailed = false
    public var requestID: UUID?

    public var showsSummaryLayout: Bool {
      report?.layout == .summary
    }

    public init(
      room: ClassRoom,
      instanceID: UUID? = nil
    ) {
      @Dependency(\.uuid) var uuid
      self.room = room
      self.instanceID = instanceID ?? uuid()
    }
  }

  public enum Action: ViewAction {
    case view(View)
    case async(AsyncAction)
    case inner(InnerAction)
    case delegate(DelegateAction)
  }

  @CasePathable
  public enum View: Equatable {
    case onAppear
    case retryTapped
    case backTapped
    case tabSelected(ClassReportTab)
    case myOpinionsTapped
  }

  @CasePathable
  public enum AsyncAction: Equatable {
    case fetch
  }

  @CasePathable
  public enum InnerAction: Equatable {
    case reportResponse(instanceID: UUID, requestID: UUID, roomID: Int, Result<ClassReport?, ClassError>)
  }

  @CasePathable
  public enum DelegateAction: Equatable {
    case dismiss
  }

  public enum CancelID: Hashable, Sendable {
    case load(UUID)
  }

  @Dependency(\.classUseCase) private var classUseCase
  @Dependency(\.uuid) private var uuid

  public var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
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

// MARK: - Action Handlers

extension ClassReportFeature {
  private func handleViewAction(
    state: inout State,
    action: View
  ) -> Effect<Action> {
    switch action {
    case .onAppear:
      guard !state.hasLoaded, !state.isLoading else { return .none }
      return .send(.async(.fetch))
    case .retryTapped:
      return .send(.async(.fetch))
    case .backTapped:
      state.requestID = nil
      state.isLoading = false
      return .merge(
        .cancel(id: CancelID.load(state.instanceID)),
        .send(.delegate(.dismiss))
      )
    case let .tabSelected(tab):
      guard state.selectedTab != tab else { return .none }
      state.selectedTab = tab
      return .none
    case .myOpinionsTapped:
      state.showsMyOpinions.toggle()
      return .none
    }
  }

  private func handleAsyncAction(
    state: inout State,
    action: AsyncAction
  ) -> Effect<Action> {
    switch action {
    case .fetch:
      let requestID = uuid()
      state.requestID = requestID
      state.isLoading = true
      state.loadFailed = false
      return .run { [classUseCase, instanceID = state.instanceID, roomID = state.room.id] send in
        let result = await Result {
          try await classUseCase.fetchReport(roomID: roomID)
        }
        .mapError(ClassError.from)
        await send(.inner(.reportResponse(
          instanceID: instanceID,
          requestID: requestID,
          roomID: roomID,
          result
        )))
      }
      .cancellable(id: CancelID.load(state.instanceID), cancelInFlight: true)
    }
  }

  private func handleInnerAction(
    state: inout State,
    action: InnerAction
  ) -> Effect<Action> {
    switch action {
    case let .reportResponse(instanceID, requestID, roomID, result):
      guard state.instanceID == instanceID,
            state.requestID == requestID,
            state.room.id == roomID else { return .none }
      state.requestID = nil
      state.hasLoaded = true
      state.isLoading = false
      switch result {
      case let .success(report):
        state.report = report
        state.loadFailed = false
      case .failure:
        state.report = nil
        state.loadFailed = true
      }
      return .none
    }
  }
}
