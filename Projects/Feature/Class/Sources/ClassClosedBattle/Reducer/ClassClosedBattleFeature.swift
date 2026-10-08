import ClassDomainInterface
import ComposableArchitecture

@Reducer
public struct ClassClosedBattleFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public var room: ClassRoom

    public init(room: ClassRoom) {
      self.room = room
    }
  }

  public enum Action: ViewAction {
    case view(View)
    case delegate(DelegateAction)
  }

  @CasePathable
  public enum View: Equatable {
    case backTapped
    case resultTapped
  }

  @CasePathable
  public enum DelegateAction: Equatable {
    case dismiss
    case openReport(ClassRoom)
  }

  public var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .view(.backTapped):
        return .send(.delegate(.dismiss))
      case .view(.resultTapped):
        return .send(.delegate(.openReport(state.room)))
      case .delegate:
        return .none
      }
    }
  }
}
