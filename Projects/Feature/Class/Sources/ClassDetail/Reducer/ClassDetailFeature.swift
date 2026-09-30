import ClassDomainInterface
import ComposableArchitecture
import Foundation

@Reducer
public struct ClassDetailFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public let room: ClassRoom
    public var deadline: Date
    public var draftDeadline: Date
    public var isDeadlineSheetPresented = false
    public var isDeleteAlertPresented = false

    public init(room: ClassRoom) {
      self.room = room
      deadline = room.deadline
      draftDeadline = room.deadline
    }
  }

  public enum Action: ViewAction, BindableAction {
    case binding(BindingAction<State>)
    case view(View)
    case delegate(DelegateAction)
  }

  public enum View {
    case backTapped
    case membersTapped
    case battleTapped
    case deadlineTapped
    case deadlineSaved
    case deleteTapped
    case deleteConfirmed
  }

  public enum DelegateAction: Equatable {
    case dismiss
    case openMembers(ClassRoom)
    case openBattle(ClassBattleSummary)
    case deleted(Int)
  }

  public var body: some Reducer<State, Action> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .binding:
        return .none
      case let .view(viewAction):
        return handleViewAction(state: &state, action: viewAction)
      case .delegate:
        return .none
      }
    }
  }
}

extension ClassDetailFeature {
  private func handleViewAction(state: inout State, action: View) -> Effect<Action> {
    switch action {
    case .backTapped:
      return .send(.delegate(.dismiss))
    case .membersTapped:
      return .send(.delegate(.openMembers(state.room)))
    case .battleTapped:
      return .send(.delegate(.openBattle(state.room.battle)))
    case .deadlineTapped:
      guard state.room.role == .owner else { return .none }
      state.draftDeadline = state.deadline
      state.isDeadlineSheetPresented = true
      return .none
    case .deadlineSaved:
      state.deadline = state.draftDeadline
      state.isDeadlineSheetPresented = false
      return .none
    case .deleteTapped:
      guard state.room.role == .owner else { return .none }
      state.isDeleteAlertPresented = true
      return .none
    case .deleteConfirmed:
      guard state.room.role == .owner else { return .none }
      state.isDeleteAlertPresented = false
      return .send(.delegate(.deleted(state.room.id)))
    }
  }
}
