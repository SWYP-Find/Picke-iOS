import ClassDomainInterface
import ComposableArchitecture
import Foundation

// MARK: - View actions

extension ClassAIChatFeature {
  func handleViewAction(
    state: inout State,
    action: View
  ) -> Effect<Action> {
    switch action {
    case .onAppear:
      guard !state.hasStarted, !state.isCompleted else { return .none }
      state.hasStarted = true
      state.isGenerating = true
      state.errorMessage = nil
      state.isModelAvailable = true
      let requestID = UUID()
      state.sessionRequestID = requestID
      let id = state.conversationID
      let stance = state.selectedStanceTitle
      let opponent = state.opponentName
      return .run { send in
        do {
          try await chatUseCase.start(id, stance, opponent)
          await send(.inner(.sessionReady(requestID)))
        } catch {
          await send(.inner(.sessionFailed(requestID, error.localizedDescription)))
        }
      }
      .cancellable(id: CancelID.session, cancelInFlight: true)

    case .onDisappear:
      let id = state.conversationID
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
      let text = state.draft.trimmingCharacters(in: .whitespacesAndNewlines)
      guard state.hasStarted, !state.isGenerating, !state.isCompleted,
            state.isModelAvailable, !text.isEmpty
      else { return .none }
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
          let reply = try await chatUseCase.respond(id, text)
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
