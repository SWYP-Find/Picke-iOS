//
//  ClassReportFeature.swift
//  Class
//
//  Created by Picke on 10/11/26.
//

import ClassDomainInterface
import ComposableArchitecture
import Foundation
import PickeCoreUtility

@Reducer
public struct ClassReportFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public let instanceID: UUID
    public var room: ClassRoom
    public var report: ClassReport?
    public var classResult: ClassResult?
    public var voteHistory: ClassVoteHistory?
    public var voteHistoryRequestID: UUID?
    public var selectedTab: ClassReportTab = .summary
    public var sourceViewState: ClassReportSourceViewState = .loading
    public var sourceError: ClassError?
    public var requestID: UUID?
    public var feedback: ClassAIPersonalFeedback?
    public var feedbackContext: ClassAIFeedbackContext?
    public var feedbackError: ClassAIFeedbackError?
    public var feedbackRequestID: UUID?
    public var insight: ClassAIInsight?
    public var insightError: ClassAIFeedbackError?
    public var insightRequestID: UUID?
    public var isGeneratingFeedback = false
    public var unknownRetryCount = 0

    public var highlightRows: [ClassReportHighlightRow] {
      guard let highlights = insight?.highlights else { return [] }
      return highlights.enumerated().map { index, evidence in
        ClassReportHighlightRow(
          id: index,
          title: "주요 의견 \(index + 1)",
          text: evidence.quote ?? evidence.content,
          isLast: index == highlights.count - 1
        )
      }
    }

    public var sourceErrorMessage: String {
      sourceError?.message ?? "리포트를 불러오지 못했어요"
    }

    public var serverFeedbackAvailabilityMessage: String {
      guard let closeAt = classResult?.closeAt else { return "" }
      return "\(closeAt.formatted(.dottedDateTimeWithWeekday)) 이후 제공돼요."
    }

    public var feedbackStatusTitle: String {
      switch feedbackViewState {
      case .pending: return "생각을 정리하고 있어요"
      case .failure:
        if feedbackError == .resultExpired { return "결과 열람 기간이 끝났어요" }
        if feedbackError == .accessDenied { return "피드백을 볼 권한이 없어요" }
        return "AI 피드백을 표시할 수 없어요"
      default: return "AI 피드백을 사용할 수 없어요"
      }
    }

    public var feedbackStatusMessage: String {
      switch feedbackViewState {
      case .pending: return "잠시 뒤 다시 확인해 주세요."
      case .failure:
        if feedbackError == .resultExpired { return "이용권 종료 후 열람 기간을 확인해 주세요." }
        if feedbackError == .accessDenied { return "클래스 참여 상태를 확인해 주세요." }
        return "서버에서 피드백을 준비하지 못했어요."
      default: return "참여 결과를 확인해 주세요."
      }
    }

    public var serverActiveMemberCount: String { String(classResult?.stats.activeMemberCount ?? 0) }
    public var serverCompletedCount: String { String(classResult?.stats.completedCount ?? 0) }
    public var serverPostVoteCount: String { String(classResult?.stats.postVoteCount ?? 0) }

    public var serverParticipationSummary: String {
      guard let stats = classResult?.stats else { return "" }
      return "참여율 \(stats.participationRate.formatted(.number.precision(.fractionLength(1))))% · "
        + "의견 작성률 \(stats.commentRate.formatted(.number.precision(.fractionLength(1))))%"
    }

    public var serverParticipationRate: String {
      guard let rate = classResult?.stats.participationRate else { return "" }
      return rate.formatted(.number.precision(.fractionLength(0...1))) + "%"
    }

    public var serverCommentRate: String {
      guard let rate = classResult?.stats.commentRate else { return "" }
      return rate.formatted(.number.precision(.fractionLength(0...1))) + "%"
    }

    public var serverParticipationCount: String {
      guard let stats = classResult?.stats else { return "" }
      return "\(stats.completedCount) / \(stats.activeMemberCount)명"
    }

    public var serverCommentCount: String {
      guard let stats = classResult?.stats else { return "" }
      return "\(stats.commentWriterCount) / \(stats.activeMemberCount)명"
    }

    public var serverParticipationProgress: Double {
      min(max((classResult?.stats.participationRate ?? 0) / 100, 0), 1)
    }

    public var serverCommentProgress: Double {
      min(max((classResult?.stats.commentRate ?? 0) / 100, 0), 1)
    }

    public var serverOptionCounts: [Int: String] {
      guard let options = classResult?.stats.options else { return [:] }
      return options.reduce(into: [:]) { values, option in
        values[option.id] = "사전 \(option.preVoteCount) · 사후 \(option.postVoteCount)"
      }
    }

    public var serverDistributionTotalText: String {
      "\(classResult?.stats.postVoteCount ?? 0)명"
    }

    public var serverDistributionProgress: Double {
      min(max((classResult?.stats.options.first?.postVoteRatio ?? 0) / 100, 0), 1)
    }

    public var serverDistributionOptionCountTexts: [Int: String] {
      guard let options = classResult?.stats.options else { return [:] }
      return options.reduce(into: [:]) { values, option in
        values[option.id] = "\(option.postVoteCount)명"
      }
    }

    public var serverDistributionOptionRatioTexts: [Int: String] {
      guard let options = classResult?.stats.options else { return [:] }
      return options.reduce(into: [:]) { values, option in
        values[option.id] = option.postVoteRatio.formatted(.number.precision(.fractionLength(0...1))) + "%"
      }
    }

    public var insightStatusMessage: String {
      if insightRequestID != nil { return "분석 결과를 불러오는 중이에요." }
      if let insightError {
        switch insightError {
        case .serverRetryAvailable, .generationFailed:
          return "AI 인사이트 생성에 실패했어요."
        case .accessDenied:
          return "AI 인사이트를 볼 권한이 없어요."
        case .resultExpired:
          return "AI 인사이트 열람 기간이 끝났어요."
        default:
          return "AI 인사이트를 불러오지 못했어요."
        }
      }
      return "분석 결과를 준비하고 있어요."
    }

    public var canRetryInsight: Bool { insightError?.isRetryable == true }

    public var feedbackViewState: ClassReportFeedbackViewState {
      if let feedback {
        return .ready(feedback)
      }
      if isGeneratingFeedback {
        return .loading
      }
      if feedbackError == .modelNotReady {
        return .pending
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
      if classResult != nil { return feedback?.perspectiveCount ?? 0 }
      return report?.resolvedOpinions.count ?? 0
    }

    public var personalPreVoteTitle: String? {
      voteHistory?.preVote.title ?? feedback?.preOption?.title
    }

    public var personalPostVoteTitle: String? {
      voteHistory?.postVote?.title ?? feedback?.postOption?.title
    }

    public var personalOpinionChanged: Bool {
      if let opinionChanged = voteHistory?.opinionChanged { return opinionChanged }
      guard let preID = voteHistory?.preVote.optionID ?? feedback?.preOption?.id,
            let postID = voteHistory?.postVote?.optionID ?? feedback?.postOption?.id else {
        return false
      }
      return preID != postID
    }

    public var personalOpinionChangeTitle: String {
      personalOpinionChanged ? "입장 변경" : "입장 유지"
    }

    public var personalPerspectiveCountText: String {
      feedback.map { String($0.perspectiveCount) } ?? "—"
    }

    public var personalCommentCountText: String {
      feedback.map { String($0.commentCount) } ?? "—"
    }

    public var myOpinionsButtonTitle: String {
      if classResult != nil, feedback == nil { return "내가 남긴 의견 보기" }
      return "내가 남긴 의견 \(myOpinionCount)개 보기"
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
    case insightRetryTapped
    case backTapped
    case closeTapped
    case tabSelected(ClassReportTab)
    case myOpinionsTapped
  }

  @CasePathable
  public enum AsyncAction: Equatable {
    case fetch
    case fetchVoteHistory
    case generateFeedback
    case fetchInsight
  }

  @CasePathable
  public enum InnerAction: Equatable {
    case resultResponse(instanceID: UUID, requestID: UUID, roomID: Int, Result<ClassResult, ClassError>)
    case voteHistoryResponse(instanceID: UUID, requestID: UUID, roomID: Int, Result<ClassVoteHistory, ClassError>)
    case reportResponse(instanceID: UUID, requestID: UUID, roomID: Int, Result<ClassReport?, ClassError>)
    case feedbackResponse(
      instanceID: UUID,
      requestID: UUID,
      roomID: Int,
      Result<ClassAIFeedbackResult, ClassAIFeedbackError>,
      wasUnknown: Bool
    )
    case insightResponse(instanceID: UUID, requestID: UUID, roomID: Int, Result<ClassAIInsight, ClassAIFeedbackError>)
  }

  @CasePathable
  public enum DelegateAction: Equatable {
    case dismiss
    case openMyOpinions(UUID)
  }

  public enum CancelID: Hashable, Sendable {
    case load(UUID)
    case voteHistory(UUID)
    case generate(UUID)
    case insight(UUID)
  }

  @Dependency(\.classResultUseCase) private var classUseCase
  @Dependency(\.classBattleUseCase) private var battleUseCase
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
            !state.isGeneratingFeedback else { return .none }
      return .send(.async(.generateFeedback))
    case .insightRetryTapped:
      guard state.canRetryInsight, state.insightRequestID == nil else { return .none }
      return .send(.async(.fetchInsight))
    case .backTapped, .closeTapped:
      state.requestID = nil
      state.voteHistoryRequestID = nil
      state.feedbackRequestID = nil
      state.insightRequestID = nil
      state.isGeneratingFeedback = false
      return .merge(
        .cancel(id: CancelID.load(state.instanceID)),
        .cancel(id: CancelID.voteHistory(state.instanceID)),
        .cancel(id: CancelID.generate(state.instanceID)),
        .cancel(id: CancelID.insight(state.instanceID)),
        .send(.delegate(.dismiss))
      )
    case let .tabSelected(tab):
      guard state.selectedTab != tab else { return .none }
      state.selectedTab = tab
      return .none
    case .myOpinionsTapped:
      guard state.sourceViewState == .ready,
            state.report != nil || state.classResult?.myReportState != nil else { return .none }
      return .send(.delegate(.openMyOpinions(state.instanceID)))
    }
  }

  private func handleAsyncAction(
    state: inout State,
    action: AsyncAction
  ) -> Effect<Action> {
    switch action {
    case .fetch:
      state.classResult = nil
      state.voteHistory = nil
      state.voteHistoryRequestID = nil
      state.sourceError = nil
      state.feedbackRequestID = nil
      state.insightRequestID = nil
      state.insight = nil
      state.insightError = nil
      state.feedback = nil
      state.feedbackContext = nil
      state.feedbackError = nil
      state.isGeneratingFeedback = false
      state.unknownRetryCount = 0
      let requestID = uuid()
      state.requestID = requestID
      state.sourceViewState = .loading
      let fetch = Effect<Action>.run { [
        classUseCase,
        instanceID = state.instanceID,
        roomID = state.room.id
      ] send in
        let result = await Result {
          try await classUseCase.fetchResult(roomID: roomID)
        }
        .mapError(ClassError.from)
        await send(.inner(.resultResponse(
          instanceID: instanceID,
          requestID: requestID,
          roomID: roomID,
          result
        )))
      }
      .cancellable(id: CancelID.load(state.instanceID), cancelInFlight: true)
      return .concatenate(
        .cancel(id: CancelID.voteHistory(state.instanceID)),
        .cancel(id: CancelID.generate(state.instanceID)),
        .cancel(id: CancelID.insight(state.instanceID)),
        fetch
      )
    case .fetchVoteHistory:
      let requestID = uuid()
      state.voteHistoryRequestID = requestID
      return .run { [battleUseCase, instanceID = state.instanceID, roomID = state.room.id] send in
        let result = await Result {
          try await battleUseCase.fetchMyVotes(classID: roomID)
        }
        .mapError(ClassError.from)
        await send(.inner(.voteHistoryResponse(
          instanceID: instanceID,
          requestID: requestID,
          roomID: roomID,
          result
        )))
      }
      .cancellable(id: CancelID.voteHistory(state.instanceID), cancelInFlight: true)
    case .generateFeedback:
      let requestID = uuid()
      state.feedbackRequestID = requestID
      state.feedbackError = nil
      state.isGeneratingFeedback = true
      return .run { [classUseCase, instanceID = state.instanceID, roomID = state.room.id] send in
        var wasUnknown = false
        var wasCancelled = false
        let result = await Result {
          try await ClassAIFeedbackResult.personal(classUseCase.fetchPersonalResult(roomID: roomID))
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
    case .fetchInsight:
      let retryServerGeneration = state.insightError == .serverRetryAvailable
      let requestID = uuid()
      state.insightRequestID = requestID
      state.insightError = nil
      return .run { [classUseCase, instanceID = state.instanceID, roomID = state.room.id] send in
        let result = await Result {
          if retryServerGeneration {
            try await classUseCase.retryInsight(roomID: roomID)
          }
          return try await classUseCase.fetchInsight(roomID: roomID)
        }
        .mapError { ($0 as? ClassAIFeedbackError) ?? .temporarilyUnavailable }
        guard !Task.isCancelled else { return }
        await send(.inner(.insightResponse(
          instanceID: instanceID,
          requestID: requestID,
          roomID: roomID,
          result
        )))
      }
      .cancellable(id: CancelID.insight(state.instanceID), cancelInFlight: true)
    }
  }

  private func handleInnerAction(
    state: inout State,
    action: InnerAction
  ) -> Effect<Action> {
    switch action {
    case let .resultResponse(instanceID, requestID, roomID, result):
      guard state.instanceID == instanceID,
            state.requestID == requestID,
            state.room.id == roomID else { return .none }
      state.requestID = nil
      switch result {
      case let .success(classResult):
        state.classResult = classResult
        state.insightError = classResult.insightState == "FAILED" ? .serverRetryAvailable : nil
        state.sourceError = nil
        state.sourceViewState = .ready
        var effects: [Effect<Action>] = []
        if state.room.role == .member {
          effects.append(.send(.async(.fetchVoteHistory)))
        }
        if classResult.myReportState != nil {
          effects.append(.send(.async(.generateFeedback)))
        }
        if state.room.role != .member,
           (classResult.insightState == "SUCCEEDED" || classResult.insightState == "LIMITED") {
          effects.append(.send(.async(.fetchInsight)))
        }
        return .merge(effects)
      case let .failure(error):
        state.classResult = nil
        state.sourceError = error
        state.sourceViewState = .failed
        return .none
      }

    case let .voteHistoryResponse(instanceID, requestID, roomID, result):
      guard state.instanceID == instanceID,
            state.voteHistoryRequestID == requestID,
            state.room.id == roomID else { return .none }
      state.voteHistoryRequestID = nil
      state.voteHistory = try? result.get()
      return .none

    case let .reportResponse(instanceID, requestID, roomID, result):
      guard state.instanceID == instanceID,
            state.requestID == requestID,
            state.room.id == roomID else { return .none }
      state.requestID = nil
      switch result {
      case let .success(report):
        state.report = report
        state.sourceError = nil
        state.sourceViewState = .ready
        return state.classResult?.myReportState == nil ? .none : .send(.async(.generateFeedback))
      case let .failure(error):
        state.report = nil
        state.sourceError = error
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
        guard case let .personal(feedback) = result else {
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
    case let .insightResponse(instanceID, requestID, roomID, result):
      guard state.instanceID == instanceID,
            state.insightRequestID == requestID,
            state.room.id == roomID else { return .none }
      state.insightRequestID = nil
      switch result {
      case let .success(insight):
        state.insight = insight
        state.insightError = nil
      case let .failure(error):
        state.insight = nil
        state.insightError = error
      }
      return .none
    }
  }
}
