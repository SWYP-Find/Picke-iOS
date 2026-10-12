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
    public var sourceViewState: ClassReportSourceViewState = .loading
    public var requestID: UUID?
    public var feedback: ClassAIPersonalFeedback?
    public var feedbackContext: ClassAIFeedbackContext?
    public var feedbackError: ClassAIFeedbackError?
    public var feedbackRequestID: UUID?
    public var isGeneratingFeedback = false
    public var unknownRetryCount = 0

    public var feedbackViewState: ClassReportFeedbackViewState {
      if let feedback {
        return .ready(feedback)
      }
      if isGeneratingFeedback {
        return .loading
      }
      if let feedbackError, feedbackError.isRetryable {
        return .retryableFailure
      }
      if let feedbackError, feedbackError != .insufficientInput, !feedbackError.isUnavailable {
        return .failure
      }
      return .unavailable
    }

    public var myOpinionCount: Int {
      report?.myOpinions.count ?? 0
    }

    public var myOpinions: [String] {
      report?.myOpinions ?? []
    }

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
    case feedbackRetryTapped
    case backTapped
    case tabSelected(ClassReportTab)
    case myOpinionsTapped
  }

  @CasePathable
  public enum AsyncAction: Equatable {
    case fetch
    case generateFeedback
  }

  @CasePathable
  public enum InnerAction: Equatable {
    case reportResponse(instanceID: UUID, requestID: UUID, roomID: Int, Result<ClassReport?, ClassError>)
    case feedbackResponse(
      instanceID: UUID,
      requestID: UUID,
      roomID: Int,
      Result<ClassAIFeedbackResult, ClassAIFeedbackError>,
      wasUnknown: Bool
    )
  }

  @CasePathable
  public enum DelegateAction: Equatable {
    case dismiss
  }

  public enum CancelID: Hashable, Sendable {
    case load(UUID)
    case generate(UUID)
  }

  @Dependency(\.classUseCase) private var classUseCase
  @Dependency(\.classAIFeedbackUseCase) private var classAIFeedbackUseCase
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
      guard state.sourceViewState == .loading, state.requestID == nil else { return .none }
      return .send(.async(.fetch))
    case .retryTapped:
      return .send(.async(.fetch))
    case .feedbackRetryTapped:
      guard state.feedbackError?.isRetryable == true,
            !state.isGeneratingFeedback,
            state.feedbackContext != nil else { return .none }
      return .send(.async(.generateFeedback))
    case .backTapped:
      state.requestID = nil
      state.feedbackRequestID = nil
      state.isGeneratingFeedback = false
      return .merge(
        .cancel(id: CancelID.load(state.instanceID)),
        .cancel(id: CancelID.generate(state.instanceID)),
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
      state.feedbackRequestID = nil
      state.feedback = nil
      state.feedbackContext = nil
      state.feedbackError = nil
      state.isGeneratingFeedback = false
      state.unknownRetryCount = 0
      let requestID = uuid()
      state.requestID = requestID
      state.sourceViewState = .loading
      let fetch = Effect<Action>.run { [classUseCase, instanceID = state.instanceID, roomID = state.room.id] send in
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
      return .concatenate(.cancel(id: CancelID.generate(state.instanceID)), fetch)
    case .generateFeedback:
      let context: ClassAIFeedbackContext
      if let retained = state.feedbackContext {
        context = retained
      } else {
        guard let report = state.report else { return .none }
        do {
          context = try .personal(room: state.room, report: report, isOwner: false)
          state.feedbackContext = context
        } catch {
          state.feedbackError = .insufficientInput
          return .none
        }
      }
      let requestID = uuid()
      state.feedbackRequestID = requestID
      state.feedbackError = nil
      state.isGeneratingFeedback = true
      return .run { [classAIFeedbackUseCase, instanceID = state.instanceID, roomID = state.room.id] send in
        var wasUnknown = false
        var wasCancelled = false
        let result = await Result {
          try await classAIFeedbackUseCase.generate(context: context)
        }
        .mapError { error in
          wasCancelled = error is CancellationError
          wasUnknown = !(error is ClassAIFeedbackError)
          return (error as? ClassAIFeedbackError) ?? .temporarilyUnavailable
        }
        guard !Task.isCancelled, !wasCancelled else { return }
        await send(.inner(.feedbackResponse(
          instanceID: instanceID,
          requestID: requestID,
          roomID: roomID,
          result,
          wasUnknown: wasUnknown
        )))
      }
      .cancellable(id: CancelID.generate(state.instanceID), cancelInFlight: true)
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
      switch result {
      case let .success(report):
        state.report = report
        state.sourceViewState = .ready
        return report == nil ? .none : .send(.async(.generateFeedback))
      case .failure:
        state.report = nil
        state.sourceViewState = .failed
      }
      return .none
    case let .feedbackResponse(instanceID, requestID, roomID, result, wasUnknown):
      guard state.instanceID == instanceID,
            state.feedbackRequestID == requestID,
            state.room.id == roomID else { return .none }
      state.feedbackRequestID = nil
      state.isGeneratingFeedback = false
      switch result {
      case let .success(result):
        guard case let .personal(feedback) = result, feedback.points.count == 3 else {
          state.feedbackError = .generationFailed
          return .none
        }
        state.feedback = feedback
        state.feedbackError = nil
      case let .failure(error):
        if wasUnknown {
          state.unknownRetryCount += 1
          state.feedbackError = state.unknownRetryCount > 1 ? .generationFailed : .temporarilyUnavailable
        } else {
          state.feedbackError = error
        }
      }
      return .none
    }
  }
}
