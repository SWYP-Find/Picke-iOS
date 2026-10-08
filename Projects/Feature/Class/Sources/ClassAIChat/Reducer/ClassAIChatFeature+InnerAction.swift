import ClassDomainInterface
import ComposableArchitecture

// MARK: - Inner actions

extension ClassAIChatFeature {
  func handleInnerAction(
    state: inout State,
    action: InnerAction
  ) -> Effect<Action> {
    switch action {
    case let .sessionReady(requestID):
      guard state.sessionRequestID == requestID else { return .none }
      state.sessionRequestID = nil
      state.isGenerating = false
      state.isModelAvailable = true
      return .none

    case let .sessionFailed(requestID, message):
      guard state.sessionRequestID == requestID else { return .none }
      state.sessionRequestID = nil
      state.isGenerating = false
      state.isModelAvailable = false
      state.errorMessage = message
      return .none

    case let .responseReceived(requestID, bubbles):
      guard state.responseRequestID == requestID else { return .none }
      state.responseRequestID = nil
      state.isGenerating = false
      state.pendingText = nil
      state.messages.append(contentsOf: bubbles.map { .init(speaker: .opponent, text: $0) })
      if state.round == 3 {
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
