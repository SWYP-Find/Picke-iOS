//
//  ClassAIChatFeature.swift
//  Class
//
//  Created by Picke on 10/11/26.
//

import ClassDomainInterface
import ComposableArchitecture
import Foundation
import PickeCoreUtility
import PickeSharedUI

@Reducer
public struct ClassAIChatFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public let room: ClassRoom
    public let battleID: Int
    public let selectedOptionID: Int
    public var conversationID: UUID
    public var round = 1
    public var messages: [ClassAIChatMessage]
    public var draft = ""
    public var isGenerating = false
    public var isCompleted = false
    public var isModelAvailable = true
    public var canRetrySession = false
    public var errorMessage: String?
    public var hasStarted = false
    public var sessionRequestID: UUID?
    public var responseRequestID: UUID?
    public var pendingText: String?
    @Presents public var customAlert: CustomAlertState<CustomAlertAction>?

    public init(
      room: ClassRoom,
      battleID: Int,
      selectedOptionID: Int,
      conversationID: UUID = UUID()
    ) {
      self.room = room
      self.battleID = battleID
      self.selectedOptionID = selectedOptionID
      self.conversationID = conversationID
      messages = []
    }

    public var selectedStanceTitle: String {
      selectedOptionID == 1 ? room.battle.optionATitle : room.battle.optionBTitle
    }

    public var opponentName: String {
      return selectedOptionID == 1 ? room.battle.philosopherB : room.battle.philosopherA
    }

    public var opponentAvatarURL: URL? {
      selectedOptionID == 1 ? room.battle.philosopherBImageURL : room.battle.philosopherAImageURL
    }

    public var quickReplies: [String] {
      ["저는 \(selectedStanceTitle)에 동의해요", "그 입장의 근거는 무엇인가요?", "다른 관점도 생각해 볼게요"]
    }

    public var totalRounds: Int {
      3
    }

    public var roundTitle: String {
      "ROUND \(min(round, totalRounds)) · 입장에 반박해보세요"
    }

    public var thinkingText: String {
      "\(opponentName)\(opponentName.josa("이", "가")) 답변을 생각하고 있어요"
    }

    /// 안내 박스 문구 — 피그마 기준으로 선택한 입장과 `반대 입장의 상대` 만 강조한다.
    public var stanceNoticeSegments: [(text: String, isHighlighted: Bool)] {
      [
        ("사전투표에서 ", false),
        ("‘\(selectedStanceTitle)’", true),
        ("\(selectedStanceTitle.josa("을", "를")) 선택하셨네요.\n", false),
        ("반대 입장의 \(opponentName)", true),
        ("\(opponentName.josa("과", "와")) \(totalRounds)라운드 토론을 시작해보세요.", false),
      ]
    }

    public var canSend: Bool {
      hasStarted && !isGenerating && !isCompleted && isModelAvailable
        && !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
  }

  public enum Action: ViewAction {
    case view(View)
    case inner(InnerAction)
    case customAlert(PresentationAction<CustomAlertAction>)
    case delegate(DelegateAction)
  }

  @CasePathable
  public enum View: Equatable {
    case onAppear
    case retryTapped
    case onDisappear
    case backTapped
    case draftChanged(String)
    case quickReplyTapped(String)
    case sendTapped
    case finalVoteTapped
  }

  @CasePathable
  public enum InnerAction: Equatable {
    case sessionReady(UUID, [String])
    case sessionFailed(UUID, String, Bool)
    case responseReceived(UUID, [String])
    case responseFailed(UUID, String)
  }

  @CasePathable
  public enum DelegateAction: Equatable {
    case dismiss
    case finalVote(battleID: Int)
  }

  enum CancelID {
    case session
    case response
  }

  @Dependency(\.classAIChatUseCase) private var chatUseCase

  public var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case let .view(viewAction):
        return handleViewAction(state: &state, action: viewAction)
      case let .inner(innerAction):
        return handleInnerAction(state: &state, action: innerAction)
      case let .customAlert(alertAction):
        return handleCustomAlertAction(state: &state, action: alertAction)
      case .delegate:
        return .none
      }
    }
    .ifLet(\.$customAlert, action: \.customAlert) {
      CustomConfirmAlert()
    }
  }
}

// MARK: - View Actions

extension ClassAIChatFeature {
  private func handleViewAction(
    state: inout State,
    action: View
  ) -> Effect<Action> {
    switch action {
    case .onAppear, .retryTapped:
      guard !state.hasStarted, !state.isCompleted else { return .none }
      let isRetry = state.canRetrySession
      let needsOpening = state.messages.isEmpty
      state.hasStarted = true
      state.isGenerating = true
      state.errorMessage = nil
      state.isModelAvailable = true
      state.canRetrySession = false
      let requestID = UUID()
      state.sessionRequestID = requestID
      let id = state.conversationID
      let opponent = state.opponentName
      let context = ClassAIChatContext(
        question: state.room.battle.title,
        selectedStance: state.selectedStanceTitle,
        opponentStance: state.selectedOptionID == 1
          ? state.room.battle.optionBTitle : state.room.battle.optionATitle,
        opponentPhilosopherName: opponent == "A 입장" || opponent == "B 입장" ? nil : opponent
      )
      return .run { send in
        do {
          if isRetry {
            await chatUseCase.end(id)
          }
          try await chatUseCase.start(id, context)
          if !needsOpening {
            guard !Task.isCancelled else { return }
            await send(.inner(.sessionReady(requestID, [])))
            return
          }
          let opening = try await chatUseCase.respond(
            id,
            "토론을 시작합니다. 상대의 입장에서 제가 선택한 입장에 반박하는 짧은 첫 질문을 한국어로 해 주세요.",
            isFinalRound: false
          )
          guard !Task.isCancelled else { return }
          let bubbles = ClassAIChatMessageUseCase.bubbles(from: opening)
          if bubbles.isEmpty {
            await send(.inner(.sessionFailed(requestID, "첫 질문을 만들지 못했어요. 다시 시도해 주세요.", true)))
          } else {
            await send(.inner(.sessionReady(requestID, bubbles)))
          }
        } catch is CancellationError {
          return
        } catch {
          guard !Task.isCancelled else { return }
          let modelError = error as? ClassAIChatError
          await send(.inner(.sessionFailed(
            requestID,
            error.localizedDescription,
            modelError != .deviceNotEligible && modelError != .unsupportedLanguage
              && modelError != .unavailable
          )))
        }
      }
      .cancellable(id: CancelID.session, cancelInFlight: true)

    case .onDisappear:
      let id = state.conversationID
      state.conversationID = UUID()
      state.hasStarted = false
      state.canRetrySession = false
      state.sessionRequestID = nil
      state.responseRequestID = nil
      state.isGenerating = false
      if let pendingText = state.pendingText {
        if state.messages.last?.speaker == .user {
          state.messages.removeLast()
        }
        state.draft = pendingText
        state.pendingText = nil
      }
      return .merge(
        .cancel(id: CancelID.session),
        .cancel(id: CancelID.response),
        .run { _ in await chatUseCase.end(id) }
      )

    case .backTapped:
      return .send(.delegate(.dismiss))

    case let .draftChanged(text):
      state.draft = text
      state.errorMessage = nil
      return .none

    case let .quickReplyTapped(text):
      guard !state.isGenerating, !state.isCompleted, state.isModelAvailable else { return .none }
      state.draft = text
      state.errorMessage = nil
      return .none

    case .sendTapped:
      guard state.canSend else { return .none }
      let text = state.draft.trimmingCharacters(in: .whitespacesAndNewlines)
      let isFinalRound = state.round == state.totalRounds
      state.isGenerating = true
      state.errorMessage = nil
      state.pendingText = text
      state.draft = ""
      state.messages.append(.init(speaker: .user, text: text))
      let requestID = UUID()
      state.responseRequestID = requestID
      let id = state.conversationID
      return .run { send in
        do {
          let reply = try await chatUseCase.respond(
            id,
            text,
            isFinalRound: isFinalRound
          )
          let bubbles = ClassAIChatMessageUseCase.bubbles(from: reply)
          if bubbles.isEmpty {
            await send(.inner(.responseFailed(requestID, "답변을 만들지 못했어요. 다시 시도해 주세요.")))
          } else {
            await send(.inner(.responseReceived(requestID, bubbles)))
          }
        } catch {
          await send(.inner(.responseFailed(requestID, error.localizedDescription)))
        }
      }
      .cancellable(id: CancelID.response, cancelInFlight: true)

    case .finalVoteTapped:
      guard state.isCompleted || !state.isModelAvailable || state.errorMessage != nil else { return .none }
      state.customAlert = .finalVote()
      return .none
    }
  }
}

// MARK: - Inner Actions

extension ClassAIChatFeature {
  private func handleInnerAction(
    state: inout State,
    action: InnerAction
  ) -> Effect<Action> {
    switch action {
    case let .sessionReady(requestID, bubbles):
      guard state.sessionRequestID == requestID else { return .none }
      state.sessionRequestID = nil
      state.isGenerating = false
      state.isModelAvailable = true
      state.canRetrySession = false
      state.messages.append(contentsOf: bubbles.map { .init(speaker: .opponent, text: $0) })
      return .none

    case let .sessionFailed(requestID, message, canRetry):
      guard state.sessionRequestID == requestID else { return .none }
      state.sessionRequestID = nil
      state.isGenerating = false
      state.isModelAvailable = false
      state.canRetrySession = canRetry
      state.hasStarted = false
      state.errorMessage = message
      return .none

    case let .responseReceived(requestID, bubbles):
      guard state.responseRequestID == requestID else { return .none }
      state.responseRequestID = nil
      state.isGenerating = false
      state.pendingText = nil
      state.messages.append(contentsOf: bubbles.map { .init(speaker: .opponent, text: $0) })
      if state.round == state.totalRounds {
        state.isCompleted = true
        state.customAlert = .finalVote()
      } else {
        state.round += 1
      }
      return .none

    case let .responseFailed(requestID, message):
      guard state.responseRequestID == requestID else { return .none }
      state.responseRequestID = nil
      state.isGenerating = false
      if state.messages.last?.speaker == .user {
        state.messages.removeLast()
      }
      state.draft = state.pendingText ?? state.draft
      state.pendingText = nil
      state.errorMessage = message
      return .none
    }
  }
}

// MARK: - Alert Actions

extension ClassAIChatFeature {
  private func handleCustomAlertAction(
    state: inout State,
    action: PresentationAction<CustomAlertAction>
  ) -> Effect<Action> {
    switch action {
    case .presented(.confirmTapped):
      state.customAlert = nil
      return .send(.delegate(.finalVote(battleID: state.battleID)))
    case .presented(.cancelTapped), .dismiss:
      state.customAlert = nil
      return .none
    case .presented:
      return .none
    }
  }
}
