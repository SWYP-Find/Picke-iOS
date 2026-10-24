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
    public var isTerminal = false
    public var isModelAvailable = true
    public var canRetrySession = false
    public var errorMessage: String?
    public var hasStarted = false
    public var sessionRequestID: UUID?
    public var responseRequestID: UUID?
    public var pendingText: String?
    public var blockedInput: String?
    public var debate: ClassDebate?
    public var replyRequestKey: UUID?
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
      debate?.participantOptionTitle ?? (selectedOptionID == 1 ? room.battle.optionATitle : room.battle.optionBTitle)
    }

    public var opponentName: String {
      debate?.philosopherName ?? (selectedOptionID == 1 ? room.battle.philosopherB : room.battle.philosopherA)
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
      let trimmedDraft = draft.trimmingCharacters(in: .whitespacesAndNewlines)
      let minimum = debate?.replyMinLength ?? 50
      let maximum = debate?.replyMaxLength ?? 1000
      return debate?.canReply == true && !isGenerating && !isCompleted
        && (minimum ... maximum).contains(trimmedDraft.count)
        && trimmedDraft != blockedInput
    }

    mutating func apply(_ debate: ClassDebate) {
      self.debate = debate
      if replyRequestKey != nil,
         debate.messages.last(where: { $0.speaker == .user })?.content == draft
      {
        draft = ""
        replyRequestKey = nil
      }
      round = debate.round
      messages = debate.messages.map { message in
        let id = UUID(uuidString: String(format: "00000000-0000-0000-0000-%012llx", message.id)) ?? UUID()
        return ClassAIChatMessage(
          id: id,
          speaker: message.speaker == .ai ? .opponent : .user,
          text: message.content
        )
      }
      hasStarted = true
      isCompleted = debate.status == .completed
      isModelAvailable = true
      canRetrySession = debate.canRetry
      errorMessage = debate.status == .failed ? ClassAIChatError.temporarilyUnavailable.localizedDescription : nil
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
    case sessionFailed(UUID, ClassAIChatError)
    case responseReceived(UUID, [String])
    case responseFailed(UUID, ClassAIChatError)
    case debateLoaded(UUID, Result<ClassDebate, ClassAIChatError>)
    case replyLoaded(UUID, Result<ClassDebate, ClassAIChatError>)
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

  @Dependency(\.classDebateUseCase) private var debateUseCase

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
      guard state.sessionRequestID == nil, state.responseRequestID == nil else { return .none }
      let isRetry = action == .retryTapped
      if isRetry, state.debate != nil, state.debate?.canRetry != true {
        return .none
      }
      let requestID = UUID()
      state.sessionRequestID = requestID
      state.isGenerating = true
      state.errorMessage = nil
      let roomID = state.room.id
      let retryServerGeneration = isRetry && state.debate?.canRetry == true
      return .run { send in
        do {
          let initial: ClassDebate
          if retryServerGeneration {
            initial = try await debateUseCase.retry(classID: roomID)
          } else {
            do {
              initial = try await debateUseCase.fetch(classID: roomID)
            } catch ClassAIChatError.noSession {
              initial = try await debateUseCase.start(classID: roomID)
            }
          }
          var debate = initial
          while debate.status == .generating, !debate.canRetry, !Task.isCancelled {
            try await Task.sleep(for: .seconds(2))
            debate = try await debateUseCase.fetch(classID: roomID)
          }
          guard !Task.isCancelled else { return }
          await send(.inner(.debateLoaded(requestID, .success(debate))))
        } catch is CancellationError {
          return
        } catch {
          guard !Task.isCancelled else { return }
          await send(.inner(.debateLoaded(requestID, .failure(error as? ClassAIChatError ?? .temporarilyUnavailable))))
        }
      }
      .cancellable(id: CancelID.session, cancelInFlight: true)

    case .onDisappear:
      state.conversationID = UUID()
      state.hasStarted = false
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
      return .merge(.cancel(id: CancelID.session), .cancel(id: CancelID.response))

    case .backTapped:
      return .send(.delegate(.dismiss))

    case let .draftChanged(text):
      guard text != state.draft else { return .none }
      state.draft = text
      state.replyRequestKey = nil
      if text.trimmingCharacters(in: .whitespacesAndNewlines) != state.blockedInput {
        state.blockedInput = nil
        state.errorMessage = nil
      }
      return .none

    case let .quickReplyTapped(text):
      guard !state.isGenerating, !state.isCompleted, state.isModelAvailable else { return .none }
      state.draft = text
      state.replyRequestKey = nil
      if text.trimmingCharacters(in: .whitespacesAndNewlines) != state.blockedInput {
        state.blockedInput = nil
        state.errorMessage = nil
      }
      return .none

    case .sendTapped:
      guard state.canSend else { return .none }
      let text = state.draft.trimmingCharacters(in: .whitespacesAndNewlines)
      guard let debate = state.debate,
            (debate.replyMinLength ... debate.replyMaxLength).contains(text.count)
      else {
        state.errorMessage = "50~1,000자로 입력해 주세요."
        return .none
      }
      state.isGenerating = true
      state.errorMessage = nil
      state.pendingText = text
      state.draft = ""
      state.messages.append(.init(speaker: .user, text: text))
      let requestID = UUID()
      state.responseRequestID = requestID
      let requestKey = state.replyRequestKey ?? UUID()
      state.replyRequestKey = requestKey
      let roomID = state.room.id
      let round = debate.round
      return .run { send in
        do {
          var result = try await debateUseCase.submitReply(
            classID: roomID,
            round: round,
            content: text,
            requestKey: requestKey
          )
          while result.status == .generating, !result.canRetry, !Task.isCancelled {
            try await Task.sleep(for: .seconds(2))
            result = try await debateUseCase.fetch(classID: roomID)
          }
          guard !Task.isCancelled else { return }
          await send(.inner(.replyLoaded(requestID, .success(result))))
        } catch is CancellationError {
          return
        } catch {
          guard !Task.isCancelled else { return }
          await send(.inner(.replyLoaded(requestID, .failure(error as? ClassAIChatError ?? .temporarilyUnavailable))))
        }
      }
      .cancellable(id: CancelID.response, cancelInFlight: true)

    case .finalVoteTapped:
      guard state.isCompleted else { return .none }
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
    case let .debateLoaded(requestID, result):
      guard state.sessionRequestID == requestID else { return .none }
      state.sessionRequestID = nil
      state.isGenerating = false
      switch result {
      case let .success(debate):
        state.apply(debate)
      case let .failure(error):
        state.errorMessage = error.localizedDescription
        state.canRetrySession = true
      }
      return .none

    case let .replyLoaded(requestID, result):
      guard state.responseRequestID == requestID else { return .none }
      state.responseRequestID = nil
      state.isGenerating = false
      switch result {
      case let .success(debate):
        state.pendingText = nil
        state.replyRequestKey = nil
        state.apply(debate)
        if debate.status == .completed {
          state.customAlert = .finalVote()
        }
      case let .failure(error):
        if state.messages.last?.speaker == .user {
          state.messages.removeLast()
        }
        state.draft = state.pendingText ?? state.draft
        state.pendingText = nil
        state.errorMessage = error.localizedDescription
      }
      return .none

    case let .sessionReady(requestID, bubbles):
      guard state.sessionRequestID == requestID else { return .none }
      state.sessionRequestID = nil
      state.isGenerating = false
      state.isModelAvailable = true
      state.canRetrySession = false
      state.isTerminal = false
      state.errorMessage = state.blockedInput == nil
        ? nil : ClassAIChatError.contentRejected.localizedDescription
      state.messages.append(contentsOf: bubbles.map { .init(speaker: .opponent, text: $0) })
      return .none

    case let .sessionFailed(requestID, error):
      guard state.sessionRequestID == requestID else { return .none }
      state.sessionRequestID = nil
      state.isGenerating = false
      state.isModelAvailable = false
      state.canRetrySession = error.canRetryOpening
      state.isTerminal = !error.canRetryOpening
      state.hasStarted = false
      state.errorMessage = state.messages.isEmpty
        ? openingErrorMessage(for: error) : error.localizedDescription
      return .none

    case let .responseReceived(requestID, bubbles):
      guard state.responseRequestID == requestID else { return .none }
      state.responseRequestID = nil
      state.isGenerating = false
      state.pendingText = nil
      state.blockedInput = nil
      state.errorMessage = nil
      state.messages.append(contentsOf: bubbles.map { .init(speaker: .opponent, text: $0) })
      if state.round == state.totalRounds {
        state.isCompleted = true
        state.customAlert = .finalVote()
      } else {
        state.round += 1
      }
      return .none

    case let .responseFailed(requestID, error):
      guard state.responseRequestID == requestID else { return .none }
      state.responseRequestID = nil
      state.isGenerating = false
      if state.messages.last?.speaker == .user {
        state.messages.removeLast()
      }
      state.draft = state.pendingText ?? state.draft
      state.pendingText = nil
      state.blockedInput = error.requiresChangedInput
        ? state.draft.trimmingCharacters(in: .whitespacesAndNewlines) : nil
      state.isTerminal = error.isTerminal
      if error.isTerminal {
        state.isModelAvailable = false
      }
      state.errorMessage = error.localizedDescription
      return .none
    }
  }

  private func openingErrorMessage(for error: ClassAIChatError) -> String {
    guard !error.canRetryOpening else { return error.localizedDescription }
    return "첫 질문을 시작할 수 없어요. \(error.localizedDescription) 최종투표로 계속해 주세요."
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
