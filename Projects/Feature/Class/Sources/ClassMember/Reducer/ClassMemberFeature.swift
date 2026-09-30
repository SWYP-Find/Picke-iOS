import ClassDomainInterface
import ComposableArchitecture

@Reducer
public struct ClassMemberFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public struct Member: Equatable, Identifiable {
      public let id: Int
      public let name: String
      public let isOwner: Bool

      public init(id: Int, name: String, isOwner: Bool = false) {
        self.id = id
        self.name = name
        self.isOwner = isOwner
      }
    }

    public let room: ClassRoom
    public var members: [Member]
    public var selectedMember: Member?

    public init(room: ClassRoom) {
      self.room = room
      members = [Member(id: 1, name: "선생님", isOwner: true)]
        + (0 ..< max(0, room.memberCount - 1)).map { index in
          Member(id: index + 2, name: "학생 \(index + 1)")
        }
    }
  }

  public enum Action: ViewAction {
    case view(View)
    case delegate(DelegateAction)
  }

  public enum View {
    case backTapped
    case removeTapped(Int)
    case removeConfirmed
    case removeCancelled
  }

  public enum DelegateAction: Equatable {
    case dismiss
  }

  public var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case let .view(viewAction):
        return handleViewAction(state: &state, action: viewAction)
      case .delegate:
        return .none
      }
    }
  }
}

extension ClassMemberFeature {
  private func handleViewAction(state: inout State, action: View) -> Effect<Action> {
    switch action {
    case .backTapped:
      return .send(.delegate(.dismiss))
    case let .removeTapped(id):
      guard state.room.role == .owner,
            let member = state.members.first(where: { $0.id == id && !$0.isOwner })
      else { return .none }
      state.selectedMember = member
      return .none
    case .removeConfirmed:
      guard let member = state.selectedMember else { return .none }
      state.members.removeAll(where: { $0.id == member.id })
      state.selectedMember = nil
      return .none
    case .removeCancelled:
      state.selectedMember = nil
      return .none
    }
  }
}
