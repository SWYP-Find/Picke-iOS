//
//  ClassOwnerDashboardFeature.swift
//  Class
//
//  Created by Picke on 10/11/26.
//

import ClassDomainInterface
import ComposableArchitecture
import Foundation

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

    public let room: ClassRoom
    public let instanceID: UUID
    public var selectedTab: ClassOwnerTab = .home
    public var showsMyOpinions = false
    public var opinionFilter: ClassOwnerOpinionFilter = .popular
    public var memberSort: ClassOwnerMemberSort = .name
    public var memberFilter: MemberFilter = .all
    public var searchText = ""
    public var members: [ClassOwnerMember] = []
    public var opinions: [ClassOwnerOpinion] = []
    public var insight: String?
    public var report: ClassReport?
    public var metrics: ClassParticipationMetrics?
    public var hasLoaded = false
    public var isLoading = false
    public var loadFailed = false
    public var requestID: UUID?
    @Presents public var management: ClassModalFeature.State?

    public init(
      room: ClassRoom,
      instanceID: UUID? = nil
    ) {
      @Dependency(\.uuid) var uuid
      self.room = room
      self.instanceID = instanceID ?? uuid()
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

    public var topOpinionViewState: TopOpinionViewState {
      guard !opinions.isEmpty else { return .empty }
      guard canSortOpinions(.popular) else { return .unavailable }
      let top = Array(opinions.sorted { ($0.recommendationCount ?? 0) > ($1.recommendationCount ?? 0) }.prefix(2))
      return .loaded(top)
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
  }

  @CasePathable
  public enum InnerAction: Equatable {
    case dashboardResponse(instanceID: UUID, requestID: UUID, roomID: Int, Result<ClassOwnerDashboardData?, ClassError>)
  }

  public enum CancelID: Hashable, Sendable {
    case load(UUID)
  }

  public enum DelegateAction: Equatable {
    case dismiss
    case editClass
    case deleteClass
    case openMemberDetail(ClassOwnerMember)
    case openReplyDetail(ClassOwnerOpinion)
    case openFeedback(ClassOwnerMember)
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
      guard !state.hasLoaded, !state.isLoading else { return .none }
      return .send(.async(.fetchDashboard))
    case .retryTapped:
      return .send(.async(.fetchDashboard))
    case .backTapped:
      state.requestID = nil
      state.isLoading = false
      return .merge(
        .cancel(id: CancelID.load(state.instanceID)),
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
      state.showsMyOpinions.toggle()
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
      let requestID = uuid()
      state.requestID = requestID
      state.isLoading = true
      state.loadFailed = false
      return .run { [classUseCase, instanceID = state.instanceID, roomID = state.room.id] send in
        let result = await Result {
          try await classUseCase.fetchOwnerDashboard(roomID: roomID)
        }
        .mapError(ClassError.from)
        await send(.inner(.dashboardResponse(
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
    case let .dashboardResponse(instanceID, requestID, roomID, result):
      guard state.instanceID == instanceID,
            state.requestID == requestID,
            state.room.id == roomID else { return .none }
      state.requestID = nil
      state.hasLoaded = true
      state.isLoading = false
      switch result {
      case let .success(dashboard):
        state.members = dashboard?.members ?? []
        state.opinions = dashboard?.opinions ?? []
        state.insight = dashboard?.insight
        state.report = dashboard?.report
        state.metrics = dashboard?.metrics
        state.loadFailed = false
      case .failure:
        state.members = []
        state.opinions = []
        state.insight = nil
        state.report = nil
        state.metrics = nil
        state.loadFailed = true
      }
      return .none
    }
  }
}
