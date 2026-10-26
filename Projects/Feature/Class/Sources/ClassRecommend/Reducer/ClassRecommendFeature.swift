//
//  ClassRecommendFeature.swift
//  Class
//
//  Created by Picke on 10/11/26.
//

import ClassDomainInterface
import ComposableArchitecture
import Foundation

@Reducer
public struct ClassRecommendFeature {
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
    public var draft: ClassTopicDraft?
    public var selectedBattleId: Int?
    public var selectedQuestionId: Int?
    public var viewState: ViewState = .loading
    public var isLoading = false

    public init(
      filter: ClassTopicFilter,
      mode: Mode = .existingContent
    ) {
      self.filter = filter
      self.mode = mode
    }

    public var conditionTitles: [String] {
      let keyword = filter.keyword.trimmingCharacters(in: .whitespacesAndNewlines)
      return (keyword.isEmpty ? [] : [keyword]) + [filter.level.title] + filter.categories.map(\.title)
    }

    public var introTitle: String {
      mode == .aiQuestions ? "AI가 주제에 어울리는\n질문을 만들었어요" : "주제에 어울리는\n배틀을 찾았어요"
    }

    public var introDescription: String {
      mode == .aiQuestions
        ? "모임에서 나눌 질문을 골라 자유롭게 수정해보세요."
        : "미리 듣고 클래스에 사용할 배틀을 골라보세요"
    }

    public var selectButtonTitle: String {
      "배틀 선택하기"
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
    case onDisappear
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
    case createDraft(ClassTopicFilter)
    case suggest(draftID: Int)
    case poll(draftID: Int)
    case select(draftID: Int, batchNo: Int, candidateID: Int)
  }

  public enum InnerAction: Equatable {
    case battles(Result<[ClassBattleSummary], ClassError>)
    case draftCreated(Result<ClassTopicDraft, ClassError>)
    case suggestionStarted(ClassTopicDraft)
    case draft(Result<ClassTopicDraft, ClassError>)
    case selected(Result<ClassTopicVersion, ClassError>)
  }

  @CasePathable
  public enum DelegateAction: Equatable {
    case dismiss
    case select(ClassBattleSummary)
    case selectAIQuestion(ClassTopicVersion, ClassTopicFilter)
    case previewRequested(ClassBattleSummary)
  }

  nonisolated enum CancelID: Hashable {
    case fetch
    case draft
    case select
  }

  @Dependency(\.classUseCase) private var classUseCase
  @Dependency(\.classTopicDraftUseCase) private var topicDraftUseCase

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

extension ClassRecommendFeature {
  private func handleViewAction(
    state: inout State,
    action: View
  ) -> Effect<Action> {
    switch action {
    case .onAppear:
      if state.mode == .aiQuestions {
        guard !state.isLoading else { return .none }
        if let draft = state.draft {
          switch draft.suggestStatus {
          case "GENERATING": return .send(.async(.poll(draftID: draft.id)))
          case "NONE": return .send(.async(.suggest(draftID: draft.id)))
          default: return .none
          }
        }
        return .send(.async(.createDraft(state.filter)))
      }
      guard state.viewState == .loading, !state.isLoading else { return .none }
      return .send(.async(.fetch(state.filter)))

    case .onDisappear:
      state.isLoading = false
      if !state.questions.isEmpty { state.viewState = .loaded }
      return .merge(
        .cancel(id: CancelID.fetch),
        .cancel(id: CancelID.draft),
        .cancel(id: CancelID.select)
      )

    case .retryTapped:
      if state.mode == .aiQuestions {
        if let draft = state.draft {
          if draft.suggestStatus == "GENERATING" {
            return .send(.async(.poll(draftID: draft.id)))
          }
          return .send(.async(.suggest(draftID: draft.id)))
        }
        return .send(.async(.createDraft(state.filter)))
      }
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
      guard state.mode == .aiQuestions, let draft = state.draft,
            draft.remainingSuggestions > 0, !state.isLoading else { return .none }
      state.selectedQuestionId = nil
      return .send(.async(.suggest(draftID: draft.id)))

    case let .previewTapped(id):
      guard state.mode == .existingContent,
            let battle = state.battles.first(where: { $0.id == id })
      else { return .none }
      return .send(.delegate(.previewRequested(battle)))

    case .selectTapped:
      if state.mode == .aiQuestions {
        guard let draft = state.draft, let candidateID = state.selectedQuestionId,
              draft.batchNo > 0, !state.isLoading else { return .none }
        return .send(.async(.select(draftID: draft.id, batchNo: draft.batchNo, candidateID: candidateID)))
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
      if state.viewState == .loading || state.viewState == .error {
        state.viewState = .loading
      }
      return .run { [classUseCase] send in
        let result = await Result {
          try await classUseCase.fetchRecommendedBattles(filter: filter)
        }
        .mapError(ClassError.from)
        await send(.inner(.battles(result)))
      }
      .cancellable(id: CancelID.fetch, cancelInFlight: true)

    case let .createDraft(filter):
      state.isLoading = true
      state.viewState = .loading
      return .run { [topicDraftUseCase] send in
        let result = await Result {
          try await topicDraftUseCase.create(filter: filter)
        }
        .mapError(ClassError.from)
        guard !Task.isCancelled else { return }
        await send(.inner(.draftCreated(result)))
      }
      .cancellable(id: CancelID.draft, cancelInFlight: true)

    case let .suggest(draftID):
      state.isLoading = true
      state.viewState = .loading
      return .run { [topicDraftUseCase] send in
        let result = await Result {
          let draft = try await topicDraftUseCase.suggest(id: draftID, filter: nil)
          guard !Task.isCancelled else { throw CancellationError() }
          await send(.inner(.suggestionStarted(draft)))
          return try await Self.pollSuggestion(draft: draft, useCase: topicDraftUseCase)
        }
        .mapError(ClassError.from)
        guard !Task.isCancelled else { return }
        await send(.inner(.draft(result)))
      }
      .cancellable(id: CancelID.draft, cancelInFlight: true)

    case let .poll(draftID):
      state.isLoading = true
      state.viewState = .loading
      return .run { [topicDraftUseCase] send in
        let result = await Result {
          let draft = try await topicDraftUseCase.fetch(id: draftID)
          return try await Self.pollSuggestion(draft: draft, useCase: topicDraftUseCase)
        }
        .mapError(ClassError.from)
        guard !Task.isCancelled else { return }
        await send(.inner(.draft(result)))
      }
      .cancellable(id: CancelID.draft, cancelInFlight: true)

    case let .select(draftID, batchNo, candidateID):
      state.isLoading = true
      return .run { [topicDraftUseCase] send in
        let result = await Result {
          try await topicDraftUseCase.select(draftID: draftID, batchNo: batchNo, candidateID: candidateID)
        }
        .mapError(ClassError.from)
        guard !Task.isCancelled else { return }
        await send(.inner(.selected(result)))
      }
      .cancellable(id: CancelID.select, cancelInFlight: true)
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
        state.viewState = battles.isEmpty ? .empty : .loaded
      case .failure:
        if state.viewState == .loading {
          state.viewState = .error
        }
      }
      return .none

    case let .draftCreated(result):
      switch result {
      case let .success(draft):
        state.draft = draft
        return .send(.async(.suggest(draftID: draft.id)))
      case .failure:
        state.isLoading = false
        state.viewState = .error
        return .none
      }

    case let .suggestionStarted(draft):
      state.draft = draft
      return .none

    case let .draft(result):
      state.isLoading = false
      switch result {
      case let .success(draft):
        state.draft = draft
        state.questions = draft.candidates.compactMap(ClassAIQuestion.init(candidate:))
        state.selectedQuestionId = nil
        state.viewState = state.questions.isEmpty ? .empty : .loaded
      case .failure:
        state.viewState = .error
      }
      return .none

    case let .selected(result):
      state.isLoading = false
      switch result {
      case let .success(version):
        return .send(.delegate(.selectAIQuestion(version, state.filter)))
      case .failure:
        state.viewState = .error
        return .none
      }
    }
  }

  private static func pollSuggestion(
    draft: ClassTopicDraft,
    useCase: any ClassTopicDraftInterface
  ) async throws -> ClassTopicDraft {
    var current = draft
    for _ in 0 ..< 90 where current.suggestStatus == "GENERATING" {
      try await Task.sleep(for: .seconds(2))
      current = try await useCase.fetch(id: draft.id)
    }
    guard current.suggestStatus != "GENERATING" else {
      throw ClassError.unknown("AI 주제 생성 시간이 초과됐어요. 다시 확인해 주세요.")
    }
    guard current.suggestStatus == "SUCCEEDED" else {
      throw ClassError.unknown(current.clarificationMessage ?? "AI 주제를 만들지 못했어요. 조건을 확인해 주세요.")
    }
    return current
  }
}
