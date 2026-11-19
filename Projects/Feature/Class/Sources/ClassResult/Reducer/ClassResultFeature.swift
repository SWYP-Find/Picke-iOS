//
//  ClassResultFeature.swift
//  Class
//
//  Created by Picke on 11/20/26.
//

import ClassDomainInterface
import ComposableArchitecture
import Foundation

/// Android `ClassResultScreen`·`ClassResultViewModel` 과 같은 결과 화면.
/// 운영자·멤버가 같은 화면을 쓰고, 서버가 준 상태에 따라 요약·내 리포트 탭을 고른다.
@Reducer
public struct ClassResultFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public let room: ClassRoom
    public var isLoading = true
    public var loaded: ClassResultContent?
    public var selectedTab: ClassResultTab = .summary
    public var isRequesting = false
    public var toastMessage: String?

    public init(room: ClassRoom) {
      self.room = room
    }

    public var isTabVisible: Bool {
      guard let loaded else { return false }
      return loaded.hasSummaryTab && loaded.hasReportTab
    }

    public var visibleTab: ClassResultTab {
      guard let loaded else { return selectedTab }
      if !loaded.hasSummaryTab {
        return .report
      }
      if !loaded.hasReportTab {
        return .summary
      }
      return selectedTab
    }

    public var isInsightRetryEnabled: Bool {
      guard let insight = loaded?.insight else { return false }
      return insight.state == .failed && insight.retryable && !isRequesting
    }
  }

  public enum Action: ViewAction {
    case view(View)
    case inner(InnerAction)
    case delegate(DelegateAction)
  }

  @CasePathable
  public enum View {
    case onAppear
    case backTapped
    case tabSelected(ClassResultTab)
    case insightRetryTapped
    case myOpinionTapped
    case toastShown
  }

  public enum InnerAction: Equatable {
    case loaded(ClassResultContent, myActivityFailed: Bool)
    case loadFailed
    case insightRetried
    case insightRetryFailed
  }

  @CasePathable
  public enum DelegateAction: Equatable {
    case dismiss
    case openMyOpinions(classID: Int)
  }

  @Dependency(\.classUseCase) private var classUseCase

  public var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case let .view(viewAction):
        return handleViewAction(state: &state, action: viewAction)
      case let .inner(innerAction):
        return handleInnerAction(state: &state, action: innerAction)
      case .delegate:
        return .none
      }
    }
  }
}

// MARK: - Action Handlers

extension ClassResultFeature {
  static let loadFailedMessage = "정보를 불러오지 못했어요"
  static let actionFailedMessage = "요청을 처리하지 못했어요"

  private func handleViewAction(
    state: inout State,
    action: View
  ) -> Effect<Action> {
    switch action {
    case .onAppear:
      guard state.isLoading, state.loaded == nil else { return .none }
      return fetchClassResult(classID: state.room.id, isOperator: state.room.role == .owner)

    case .backTapped:
      return .send(.delegate(.dismiss))

    case let .tabSelected(tab):
      state.selectedTab = tab
      return .none

    case .insightRetryTapped:
      guard state.isInsightRetryEnabled else { return .none }
      state.isRequesting = true
      let classID = state.room.id
      return .run { [classUseCase] send in
        do {
          try await classUseCase.retryInsight(roomID: classID)
          await send(.inner(.insightRetried))
        } catch {
          await send(.inner(.insightRetryFailed))
        }
      }

    case .myOpinionTapped:
      return .send(.delegate(.openMyOpinions(classID: state.room.id)))

    case .toastShown:
      state.toastMessage = nil
      return .none
    }
  }

  private func handleInnerAction(
    state: inout State,
    action: InnerAction
  ) -> Effect<Action> {
    switch action {
    case let .loaded(loaded, myActivityFailed):
      state.isLoading = false
      state.loaded = loaded
      if myActivityFailed {
        state.toastMessage = Self.loadFailedMessage
      }
      return .none

    case .loadFailed:
      state.isLoading = false
      state.toastMessage = Self.loadFailedMessage
      return .none

    case .insightRetried:
      // 재생성 요청이 접수되면 서버는 PENDING 을 돌려준다.
      state.isRequesting = false
      state.loaded?.insight = ClassResultInsightBoard(state: .pending, insightText: nil, retryable: false)
      return .none

    case .insightRetryFailed:
      state.isRequesting = false
      state.toastMessage = Self.actionFailedMessage
      return .none
    }
  }

  /// Android `ClassResultViewModel.fetchClassResult`.
  private func fetchClassResult(classID: Int, isOperator: Bool) -> Effect<Action> {
    .run { [classUseCase] send in
      let base: (ClassResult, ClassRoom, ClassBattleSession)
      do {
        async let result = classUseCase.fetchResult(roomID: classID)
        async let detail = classUseCase.fetchClass(id: classID)
        async let session = classUseCase.fetchBattle(classID: classID)
        base = try await (result, detail, session)
      } catch {
        await send(.inner(.loadFailed))
        return
      }
      let (result, detail, session) = base
      let hasSummaryTab = isOperator && result.insightState != nil
      let hasReportTab = result.myReportState != nil

      async let insightTask: ClassResultInsightBoard? = hasSummaryTab
        ? classUseCase.fetchInsightBoard(roomID: classID)
        : nil
      async let reportTask: ClassResultMyReportBoard? = hasReportTab
        ? classUseCase.fetchMyReportBoard(roomID: classID)
        : nil
      async let activityTask: ClassMyActivity? = hasReportTab
        ? classUseCase.fetchMyActivity(roomID: classID, cursor: nil)
        : nil

      let insight: ClassResultInsightBoard?
      let report: ClassResultMyReportBoard?
      do {
        insight = try await insightTask
        report = try await reportTask
      } catch {
        await send(.inner(.loadFailed))
        return
      }
      let activity = try? await activityTask
      let categoryName = session.battle.categoryTags.first
      let loaded = ClassResultContent(
        className: detail.name,
        isInProgress: !result.closed,
        tag: categoryName.map { "#\($0)" } ?? "",
        battleTitle: session.battle.title,
        deadline: result.closeAt,
        hasSummaryTab: hasSummaryTab,
        hasReportTab: hasReportTab,
        stats: result.stats,
        insight: insight,
        report: report,
        receivedLikeCount: activity?.receivedLikeCount
      )
      await send(.inner(.loaded(loaded, myActivityFailed: hasReportTab && activity == nil)))
    }
  }
}
