//
//  ClassRecommendFeature.swift
//  Class
//

import ClassDomainInterface
import ComposableArchitecture
import Foundation

@Reducer
public struct ClassRecommendFeature {
  @Dependency(\.classUseCase) private var classUseCase

  public init() {}

  public enum Mode: Equatable {
    case existingContent
    case aiQuestions
  }

  @ObservableState
  public struct State: Equatable {
    public enum ViewState: Equatable {
      case loading
      case error
      case empty
      case loaded
    }

    public var filter: ClassTopicFilter
    public var mode: Mode
    public var battles: [ClassBattleSummary] = []
    public var questions: [ClassAIQuestion] = []
    public var selectedBattleId: Int?
    public var selectedQuestionId: Int?
    public var isLoading = false
    public var loadFailed = false

    public init(filter: ClassTopicFilter, mode: Mode = .existingContent) {
      self.filter = filter
      self.mode = mode
    }

    public var conditionTitles: [String] {
      [filter.level.title, filter.category?.title].compactMap(\.self)
    }

    public var resultTitle: String {
      "추천 결과 \(mode == .aiQuestions ? questions.count : battles.count)개"
    }

    public var selectedBattle: ClassBattleSummary? {
      battles.first { $0.id == selectedBattleId }
    }

    public var selectedQuestion: ClassAIQuestion? {
      questions.first { $0.id == selectedQuestionId }
    }

    public var canSelect: Bool {
      mode == .aiQuestions ? selectedQuestion != nil : selectedBattle != nil
    }

    public var viewState: ViewState {
      if mode == .aiQuestions {
        return questions.isEmpty ? .empty : .loaded
      }
      if loadFailed && battles.isEmpty {
        return .error
      }
      if isLoading && battles.isEmpty {
        return .loading
      }
      return battles.isEmpty ? .empty : .loaded
    }
  }

  public enum Action: ViewAction {
    case view(View)
    case async(AsyncAction)
    case inner(InnerAction)
    case delegate(DelegateAction)
  }

  @CasePathable
  public enum View {
    case onAppear
    case retryTapped
    case backTapped
    case editConditionTapped
    case battleTapped(Int)
    case questionTapped(Int)
    case recommendAgainTapped
    case previewTapped(Int)
    case selectTapped
  }

  public enum AsyncAction: Equatable {
    case fetch(ClassTopicFilter)
  }

  public enum InnerAction: Equatable {
    case battles(Result<[ClassBattleSummary], ClassError>)
  }

  @CasePathable
  public enum DelegateAction: Equatable {
    case dismiss
    case select(ClassBattleSummary)
    case selectAIQuestion(ClassAIQuestion)
  }

  nonisolated enum CancelID: Hashable {
    case fetch
  }

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

extension ClassRecommendFeature {
  private func handleViewAction(
    state: inout State,
    action: View
  ) -> Effect<Action> {
    switch action {
    case .onAppear:
      if state.mode == .aiQuestions {
        if state.questions.isEmpty {
          state.questions = ClassAIQuestion.examples
        }
        return .none
      }
      guard state.battles.isEmpty else { return .none }
      return .send(.async(.fetch(state.filter)))

    case .retryTapped:
      guard state.mode == .existingContent else { return .none }
      return .send(.async(.fetch(state.filter)))

    case .backTapped, .editConditionTapped:
      return .send(.delegate(.dismiss))

    case let .battleTapped(id):
      state.selectedBattleId = state.selectedBattleId == id ? nil : id
      return .none

    case let .questionTapped(id):
      guard state.questions.contains(where: { $0.id == id }) else { return .none }
      state.selectedQuestionId = state.selectedQuestionId == id ? nil : id
      return .none

    case .recommendAgainTapped:
      guard state.mode == .aiQuestions else { return .none }
      state.questions = Array(state.questions.dropFirst()) + state.questions.prefix(1)
      state.selectedQuestionId = nil
      return .none

    case .previewTapped:
      return .none

    case .selectTapped:
      if state.mode == .aiQuestions {
        guard let question = state.selectedQuestion else { return .none }
        return .send(.delegate(.selectAIQuestion(question)))
      }
      guard let battle = state.selectedBattle else { return .none }
      return .send(.delegate(.select(battle)))
    }
  }

  private func handleAsyncAction(
    state: inout State,
    action: AsyncAction
  ) -> Effect<Action> {
    switch action {
    case let .fetch(filter):
      state.isLoading = true
      state.loadFailed = false
      return .run { [classUseCase] send in
        let result = await Result {
          try await classUseCase.fetchRecommendedBattles(filter: filter)
        }
        .mapError(ClassError.from)
        await send(.inner(.battles(result)))
      }
      .cancellable(id: CancelID.fetch, cancelInFlight: true)
    }
  }

  private func handleInnerAction(
    state: inout State,
    action: InnerAction
  ) -> Effect<Action> {
    switch action {
    case let .battles(result):
      state.isLoading = false
      switch result {
      case let .success(battles):
        state.battles = battles
      case .failure:
        state.loadFailed = true
      }
      return .none
    }
  }
}
