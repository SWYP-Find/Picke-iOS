import ComposableArchitecture
import PickeSharedUI

// MARK: - Alert actions

extension ClassAIChatFeature {
  func handleCustomAlertAction(
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
