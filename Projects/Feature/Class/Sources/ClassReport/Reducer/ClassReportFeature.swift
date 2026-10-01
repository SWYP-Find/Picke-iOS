import ClassDomainInterface
import ComposableArchitecture

@Reducer
public struct ClassReportFeature {
  public init() {}

  public enum Tab: String, CaseIterable, Hashable {
    case summary = "요약"
    case participation = "내 참여"
    case classResult = "클래스 결과"
    case feedback = "피드백"
  }

  @ObservableState
  public struct State: Equatable {
    public var room: ClassRoom
    public var selectedTab: Tab = .summary
    public var isChartDrawn = false

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
    case tabSelected(Tab)
    case chartAnimationStarted
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
        state.isChartDrawn = false
        return .none
      case .view(.chartAnimationStarted):
        if state.selectedTab == .classResult {
          state.isChartDrawn = true
        }
        return .none
      case .delegate:
        return .none
      }
    }
  }
}
