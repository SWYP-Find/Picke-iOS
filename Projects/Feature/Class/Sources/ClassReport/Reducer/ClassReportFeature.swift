import ClassDomainInterface
import ComposableArchitecture

@Reducer
public struct ClassReportFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public var room: ClassRoom
    public var selectedTab: ClassReportTab = .summary
    public var showsMyOpinions = false

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
    case tabSelected(ClassReportTab)
    case myOpinionsTapped
  }

  @CasePathable
  public enum DelegateAction: Equatable {
    case dismiss
  }

  public var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .view(.backTapped):
        return .send(.delegate(.dismiss))
      case let .view(.tabSelected(tab)):
        guard state.selectedTab != tab else { return .none }
        state.selectedTab = tab
        return .none
      case .view(.myOpinionsTapped):
        state.showsMyOpinions.toggle()
        return .none
      case .delegate:
        return .none
      }
    }
  }
}
