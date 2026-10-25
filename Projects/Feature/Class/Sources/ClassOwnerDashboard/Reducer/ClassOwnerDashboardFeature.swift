//
//  ClassOwnerDashboardFeature.swift
//  Class
//
//  Created by Picke on 10/11/26.
//

import ClassDomainInterface
import ComposableArchitecture
import Foundation
import PickeCoreUtility

@Reducer
public struct ClassOwnerDashboardFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public enum MemberViewState: Equatable {
      case unavailable
      case noSearchResults
      case loaded([ClassOwnerMember])
    }

    public enum OpinionViewState: Equatable {
      case empty
      case loaded([ClassOwnerOpinion])
    }

    public enum TopOpinionViewState: Equatable {
      case empty
      case unavailable
      case loaded([ClassOwnerOpinion])
    }

    public enum MemberSummaryState: Equatable {
      case unavailable
      case empty
      case loaded([ClassOwnerMember])
    }

    public var room: ClassRoom
    public let instanceID: UUID
    public var selectedTab: ClassOwnerTab = .home
    public var opinionFilter: ClassOwnerOpinionFilter = .popular
    public var memberSort: ClassOwnerMemberSort = .name
    public var memberFilter: MemberFilter = .all
    public var searchText = ""
    public var members: [ClassOwnerMember] = []
    public var opinions: [ClassOwnerOpinion] = []
    public var dashboard: ClassOwnerDashboardData?
    public var classResult: ClassResult?
    public var insightContext: ClassAIFeedbackContext?
    public var feedbackContext: ClassAIFeedbackContext?
    public var generatedInsight: String?
    public var serverInsight: ClassAIInsight?
    public var generatedFeedback: ClassAIPersonalFeedback?
    public var insightError: ClassAIFeedbackError?
    public var feedbackError: ClassAIFeedbackError?
    public var insightRequestID: UUID?
    public var feedbackRequestID: UUID?
    public var isGeneratingInsight = false
    public var isGeneratingFeedback = false
    public var insightUnknownRetryCount = 0
    public var feedbackUnknownRetryCount = 0
    public var report: ClassReport?
    public var metrics: ClassParticipationMetrics?
    public var sourceViewState: ClassOwnerDashboardSourceViewState = .loading
    public var requestID: UUID?
    @Presents public var management: ClassModalFeature.State?

    public var serverParticipationRate: String {
      guard let stats = classResult?.stats else { return "" }
      return "\(stats.participationRate.formatted(.number.precision(.fractionLength(1))))%"
    }

    public var serverCommentRate: String {
      guard let stats = classResult?.stats else { return "" }
      return "\(stats.commentRate.formatted(.number.precision(.fractionLength(1))))%"
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
      (classResult?.stats.participationRate ?? 0) / 100
    }

    public var serverCommentProgress: Double {
      (classResult?.stats.commentRate ?? 0) / 100
    }

    public func serverOptionSummary(_ option: ClassResultOption) -> String {
      "\(option.postVoteCount)명 · \(option.postVoteRatio.formatted(.number.precision(.fractionLength(1))))%"
    }

    public init(
      room: ClassRoom,
      instanceID: UUID? = nil
    ) {
      @Dependency(\.uuid) var uuid
      self.room = room
      self.instanceID = instanceID ?? uuid()
    }

    public var deadlineText: String {
      guard room.deadline != .distantFuture else { return "마감일 없음" }
      return room.deadline.formatted(.dottedDateTimeWithWeekday) + "까지"
    }

    public var insightViewState: ClassOwnerDashboardInsightViewState {
      if let generatedInsight {
        return .ready(generatedInsight)
      }
      if isGeneratingInsight {
        return .loading
      }
      if insightError == .modelNotReady {
        return .pending
      }
      if let insightError, insightError.isRetryable {
        return .retryableFailure
      }
      if let insightError, insightError != .insufficientInput, !insightError.isUnavailable {
        return .failure
      }
      return .unavailable
    }

    public var feedbackViewState: ClassOwnerDashboardFeedbackViewState {
      if let generatedFeedback {
        return .ready(generatedFeedback)
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
      if classResult != nil { return generatedFeedback?.perspectiveCount ?? 0 }
      return myOpinions.count
    }

    public var myOpinions: [ClassReportOpinion] {
      report?.resolvedOpinions ?? []
    }

    public var myOpinionsTitle: String {
      "내가 남긴 의견 \(myOpinionCount)개 보기"
    }

    public var canOpenMyOpinions: Bool {
      selectedTab == .report
        && sourceViewState == .ready
        && (report != nil || classResult?.myReportState != nil)
        && management == nil
    }

    public var searchedMembers: [ClassOwnerMember] {
      let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
      return query.isEmpty ? members : members.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    public var visibleMembers: [ClassOwnerMember] {
      let searched = searchedMembers
      let matching: [ClassOwnerMember] = switch memberFilter {
      case .all: searched
      case .participated: searched.filter { $0.participationCount > 0 }
      case .notParticipated: searched.filter { $0.participationCount == 0 }
      }
      switch memberSort {
      case .name:
        return matching.sorted { $0.name < $1.name }
      case .participation:
        return matching.sorted { $0.participationCount > $1.participationCount }
      case .needsReview:
        return matching.sorted { $0.needsReview && !$1.needsReview }
      }
    }

    public var visibleOpinions: [ClassOwnerOpinion] {
      guard let activeOpinionFilter else { return opinions }
      switch activeOpinionFilter {
      case .latest:
        return opinions.sorted { ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast) }
      case .popular:
        return opinions.sorted { ($0.recommendationCount ?? 0) > ($1.recommendationCount ?? 0) }
      }
    }

    public var activeOpinionFilter: ClassOwnerOpinionFilter? {
      canSortOpinions(opinionFilter) ? opinionFilter : nil
    }

    /// 첫 항목은 추천 1위, 두 번째 항목은 대댓글 1위이며 같은 의견일 수 있다.
    public var topOpinionViewState: TopOpinionViewState {
      guard !opinions.isEmpty else { return .empty }
      guard canSortOpinions(.popular) else { return .unavailable }
      let recommended = opinions.sorted {
        let lhs = $0.recommendationCount ?? 0
        let rhs = $1.recommendationCount ?? 0
        return lhs == rhs ? $0.id < $1.id : lhs > rhs
      }
      guard let best = recommended.first else { return .empty }
      let discussed = opinions.sorted {
        return $0.replyCount == $1.replyCount ? $0.id < $1.id : $0.replyCount > $1.replyCount
      }
      guard opinions.count > 1, let mostDiscussed = discussed.first, mostDiscussed.replyCount > 0 else {
        return .loaded([best])
      }
      return .loaded([best, mostDiscussed])
    }

    public var memberViewState: MemberViewState {
      guard !members.isEmpty else { return .unavailable }
      let visible = visibleMembers
      return visible.isEmpty ? .noSearchResults : .loaded(visible)
    }

    public var needsReviewViewState: MemberSummaryState {
      guard !members.isEmpty else { return .unavailable }
      let matching = members.filter(\.needsReview)
      return matching.isEmpty ? .empty : .loaded(matching)
    }

    public var highParticipationViewState: MemberSummaryState {
      guard !members.isEmpty else { return .unavailable }
      let matching = Array(members.filter { $0.participationCount > 0 }
        .sorted { $0.participationCount > $1.participationCount }
        .prefix(3))
      return matching.isEmpty ? .empty : .loaded(matching)
    }

    public var opinionViewState: OpinionViewState {
      let visible = visibleOpinions
      return visible.isEmpty ? .empty : .loaded(visible)
    }

    public func canSortOpinions(_ filter: ClassOwnerOpinionFilter) -> Bool {
      guard !opinions.isEmpty else { return false }
      switch filter {
      case .popular: return opinions.allSatisfy { $0.recommendationCount != nil }
      case .latest: return opinions.allSatisfy { $0.createdAt != nil }
      }
    }

    public var availableOpinionFilters: Set<ClassOwnerOpinionFilter> {
      Set(ClassOwnerOpinionFilter.allCases.filter(canSortOpinions))
    }
  }

  public enum MemberFilter: CaseIterable, Hashable, Sendable {
    case all
    case participated
    case notParticipated
  }

  public enum Action: ViewAction {
    case view(View)
    case async(AsyncAction)
    case inner(InnerAction)
    case delegate(DelegateAction)
    case management(PresentationAction<ClassModalFeature.Action>)
  }

  @CasePathable
  public enum View: Equatable {
    case onAppear
    case retryTapped
    case insightRetryTapped
    case feedbackRetryTapped
    case backTapped
    case managementTapped
    case managementDismissed
    case managementEditTapped
    case managementDeleteTapped
    case tabSelected(ClassOwnerTab)
    case myOpinionsTapped
    case opinionFilterSelected(ClassOwnerOpinionFilter)
    case memberSortSelected(ClassOwnerMemberSort)
    case memberFilterSelected(MemberFilter)
    case searchTextChanged(String)
    case memberTapped(Int)
    case opinionTapped(Int)
    case feedbackTapped(Int)
  }

  @CasePathable
  public enum AsyncAction: Equatable {
    case fetchDashboard
    case generateInsight
    case generatePersonal
  }

  @CasePathable
  public enum InnerAction: Equatable {
    case dashboardResponse(instanceID: UUID, requestID: UUID, roomID: Int, Result<ClassOwnerDashboardData?, ClassError>)
    case resultResponse(instanceID: UUID, requestID: UUID, roomID: Int, Result<ClassResult, ClassError>)
    case insightResponse(
      instanceID: UUID,
      requestID: UUID,
      roomID: Int,
      Result<ClassAIFeedbackResult, ClassAIFeedbackError>,
      wasUnknown: Bool
    )
    case feedbackResponse(
      instanceID: UUID,
      requestID: UUID,
      roomID: Int,
      Result<ClassAIFeedbackResult, ClassAIFeedbackError>,
      wasUnknown: Bool
    )
  }

  public enum CancelID: Hashable, Sendable {
    case load(UUID)
    case generate(UUID)
    case generatePersonal(UUID)
  }

  public enum DelegateAction: Equatable {
    case dismiss
    case openMyOpinions(UUID)
    case editClass
    case deleteClass
    case openMemberDetail(ClassOwnerMember)
    case openReplyDetail(ClassOwnerOpinion)
    case openFeedback(ClassOwnerMember)
  }

  @Dependency(\.classResultUseCase) private var classResultUseCase
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
      case .delegate, .management:
        return .none
      }
    }
    .ifLet(\.$management, action: \.management) {
      ClassModalFeature()
    }
  }
}

// MARK: - Action Handlers

extension ClassOwnerDashboardFeature {
  private func handleViewAction(
    state: inout State,
    action: View
  ) -> Effect<Action> {
    switch action {
    case .onAppear:
      guard state.sourceViewState == .loading, state.requestID == nil else { return .none }
      return .send(.async(.fetchDashboard))
    case .retryTapped:
      return .send(.async(.fetchDashboard))
    case .insightRetryTapped:
      guard state.insightError?.isRetryable == true,
            !state.isGeneratingInsight else { return .none }
      return .send(.async(.generateInsight))
    case .feedbackRetryTapped:
      guard state.feedbackError?.isRetryable == true,
            !state.isGeneratingFeedback else { return .none }
      return .send(.async(.generatePersonal))
    case .backTapped:
      state.requestID = nil
      state.insightRequestID = nil
      state.feedbackRequestID = nil
      state.isGeneratingInsight = false
      state.isGeneratingFeedback = false
      return .merge(
        .cancel(id: CancelID.load(state.instanceID)),
        .cancel(id: CancelID.generate(state.instanceID)),
        .cancel(id: CancelID.generatePersonal(state.instanceID)),
        .send(.delegate(.dismiss))
      )
    case .managementTapped:
      guard state.room.role == .owner else { return .none }
      state.management = .init(kind: .management)
    case .managementDismissed:
      state.management = nil
    case .managementEditTapped:
      state.management = nil
      return .send(.delegate(.editClass))
    case .managementDeleteTapped:
      state.management = nil
      return .send(.delegate(.deleteClass))
    case let .tabSelected(tab):
      state.selectedTab = tab
    case .myOpinionsTapped:
      guard state.canOpenMyOpinions else { return .none }
      return .send(.delegate(.openMyOpinions(state.instanceID)))
    case let .opinionFilterSelected(filter):
      guard state.canSortOpinions(filter) else { return .none }
      state.opinionFilter = filter
    case let .memberSortSelected(sort):
      state.memberSort = sort
    case let .memberFilterSelected(filter):
      guard !state.members.isEmpty || filter == .all else { return .none }
      state.memberFilter = filter
    case let .searchTextChanged(text):
      state.searchText = text
    case let .memberTapped(id):
      guard let member = state.members.first(where: { $0.id == id }) else { return .none }
      return .send(.delegate(.openMemberDetail(member)))
    case let .opinionTapped(id):
      guard let opinion = state.opinions.first(where: { $0.id == id }) else { return .none }
      return .send(.delegate(.openReplyDetail(opinion)))
    case let .feedbackTapped(id):
      guard let member = state.members.first(where: { $0.id == id }) else { return .none }
      return .send(.delegate(.openFeedback(member)))
    }
    return .none
  }

  private func handleAsyncAction(
    state: inout State,
    action: AsyncAction
  ) -> Effect<Action> {
    switch action {
    case .fetchDashboard:
      state.classResult = nil
      state.insightRequestID = nil
      state.feedbackRequestID = nil
      state.generatedInsight = nil
      state.serverInsight = nil
      state.generatedFeedback = nil
      state.insightContext = nil
      state.feedbackContext = nil
      state.insightError = nil
      state.feedbackError = nil
      state.isGeneratingInsight = false
      state.isGeneratingFeedback = false
      state.insightUnknownRetryCount = 0
      state.feedbackUnknownRetryCount = 0
      let requestID = uuid()
      state.requestID = requestID
      state.sourceViewState = .loading
      let fetch = Effect<Action>.run { [
        classResultUseCase,
        instanceID = state.instanceID,
        roomID = state.room.id
      ] send in
        let result = await Result {
          try await classResultUseCase.fetch(roomID: roomID)
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
        .cancel(id: CancelID.generate(state.instanceID)),
        .cancel(id: CancelID.generatePersonal(state.instanceID)),
        fetch
      )
    case .generateInsight:
      let retryServerGeneration = state.insightError == .serverRetryAvailable
      let requestID = uuid()
      state.insightRequestID = requestID
      state.insightError = nil
      state.isGeneratingInsight = true
      return .run { [classResultUseCase, instanceID = state.instanceID, roomID = state.room.id] send in
        var wasUnknown = false
        var wasCancelled = false
        let result = await Result {
          if retryServerGeneration {
            try await classResultUseCase.retryInsight(roomID: roomID)
          }
          return try await ClassAIFeedbackResult.serverInsight(classResultUseCase.fetchInsight(roomID: roomID))
        }
        .mapError { error in
          wasCancelled = error is CancellationError
          wasUnknown = !(error is ClassAIFeedbackError)
          return (error as? ClassAIFeedbackError) ?? .temporarilyUnavailable
        }
        guard !Task.isCancelled, !wasCancelled else { return }
        await send(.inner(.insightResponse(
          instanceID: instanceID,
          requestID: requestID,
          roomID: roomID,
          result,
          wasUnknown: wasUnknown
        )))
      }
      .cancellable(id: CancelID.generate(state.instanceID), cancelInFlight: true)
    case .generatePersonal:
      let requestID = uuid()
      state.feedbackRequestID = requestID
      state.feedbackError = nil
      state.isGeneratingFeedback = true
      return .run { [classResultUseCase, instanceID = state.instanceID, roomID = state.room.id] send in
        var wasUnknown = false
        var wasCancelled = false
        let result = await Result {
          try await ClassAIFeedbackResult.personal(classResultUseCase.fetchPersonal(roomID: roomID))
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
      .cancellable(id: CancelID.generatePersonal(state.instanceID), cancelInFlight: true)
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
        state.sourceViewState = .ready
        switch (classResult.insightState != nil, classResult.myReportState != nil) {
        case (true, true):
          return .merge(
            .send(.async(.generateInsight)),
            .send(.async(.generatePersonal))
          )
        case (true, false):
          return .send(.async(.generateInsight))
        case (false, true):
          return .send(.async(.generatePersonal))
        case (false, false):
          return .none
        }
      case .failure:
        state.classResult = nil
        state.sourceViewState = .failed
      }
      return .none
    case let .dashboardResponse(instanceID, requestID, roomID, result):
      guard state.instanceID == instanceID,
            state.requestID == requestID,
            state.room.id == roomID else { return .none }
      state.requestID = nil
      switch result {
      case let .success(dashboard):
        state.dashboard = dashboard
        state.members = dashboard?.members ?? []
        state.opinions = dashboard?.opinions ?? []
        state.report = dashboard?.report
        state.metrics = dashboard?.metrics
        state.sourceViewState = .ready
        guard dashboard != nil else { return .none }
        return .merge(.send(.async(.generateInsight)), .send(.async(.generatePersonal)))
      case .failure:
        state.dashboard = nil
        state.members = []
        state.opinions = []
        state.report = nil
        state.metrics = nil
        state.sourceViewState = .failed
      }
      return .none
    case let .insightResponse(instanceID, requestID, roomID, result, wasUnknown):
      guard state.instanceID == instanceID,
            state.insightRequestID == requestID,
            state.room.id == roomID else { return .none }
      state.insightRequestID = nil
      state.isGeneratingInsight = false
      switch result {
      case let .success(result):
        switch result {
        case let .serverInsight(insight):
          state.generatedInsight = insight.text
          state.serverInsight = insight
        case let .classInsight(insight):
          state.generatedInsight = insight
          state.serverInsight = nil
        case .personal:
          state.insightError = .generationFailed
          return .none
        }
        state.insightError = nil
      case let .failure(error):
        if wasUnknown {
          state.insightUnknownRetryCount += 1
          state.insightError = state.insightUnknownRetryCount > 1 ? .generationFailed : .temporarilyUnavailable
        } else {
          state.insightError = error
        }
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
        state.generatedFeedback = feedback
        state.feedbackError = nil
      case let .failure(error):
        if wasUnknown {
          state.feedbackUnknownRetryCount += 1
          state.feedbackError = state.feedbackUnknownRetryCount > 1 ? .generationFailed : .temporarilyUnavailable
        } else {
          state.feedbackError = error
        }
      }
      return .none
    }
  }
}
