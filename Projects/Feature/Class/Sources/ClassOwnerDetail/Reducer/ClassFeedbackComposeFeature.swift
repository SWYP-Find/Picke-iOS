import ClassDomainInterface
import ComposableArchitecture
import Foundation

@Reducer
public struct ClassFeedbackComposeFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public let room: ClassRoom
    public let memberName: String
    public var feedback = ""
    public var showUnavailableAlert = false

    public init(room: ClassRoom, memberName: String) {
      self.room = room
      self.memberName = memberName
    }
  }

  public enum Action: ViewAction, BindableAction {
    case binding(BindingAction<State>)
    case view(View)
    case delegate(DelegateAction)
  }

  @CasePathable
  public enum View: Equatable {
    case backTapped
    case cancelTapped
    case submitTapped
  }

  @CasePathable
  public enum DelegateAction: Equatable {
    case dismiss
    case submitted(String)
  }

  public var body: some Reducer<State, Action> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .binding:
        return .none
      case .view(.backTapped), .view(.cancelTapped):
        return .send(.delegate(.dismiss))
      case .view(.submitTapped):
        let feedback = state.feedback.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !feedback.isEmpty else { return .none }
        state.showUnavailableAlert = true
        return .none
      case .delegate:
        return .none
      }
    }
  }
}
