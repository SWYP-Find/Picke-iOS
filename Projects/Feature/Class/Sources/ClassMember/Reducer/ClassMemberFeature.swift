import ClassDomainInterface
import ComposableArchitecture
import Foundation

@Reducer
public struct ClassMemberFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public enum ViewState: Equatable {
      case unavailable
      case noSearchResults
      case members([ClassMember])
    }

    public let room: ClassRoom
    public var members: [ClassMember]
    public var searchText = ""
    public var appliedFilter = ClassMemberFilterFeature.State()
    @Presents public var filter: ClassMemberFilterFeature.State?

    public init(room: ClassRoom, members: [ClassMember] = []) {
      self.room = room
      self.members = members
    }

    public var visibleMembers: [ClassMember] {
      let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
      let filteredMembers = query.isEmpty
        ? members
        : members.filter { $0.name.localizedCaseInsensitiveContains(query) }

      switch appliedFilter.sort {
      case .name:
        return filteredMembers.sorted {
          $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
      case .comments, .replies, .recommendations:
        return filteredMembers
      }
    }

    public var viewState: ViewState {
      guard !members.isEmpty else { return .unavailable }
      let visible = visibleMembers
      return visible.isEmpty ? .noSearchResults : .members(visible)
    }
  }

  public enum Action: ViewAction, BindableAction {
    case binding(BindingAction<State>)
    case view(View)
    case filter(PresentationAction<ClassMemberFilterFeature.Action>)
    case delegate(DelegateAction)
  }

  public enum View {
    case backTapped
    case filterTapped
    case removeTapped(Int)
  }

  public enum DelegateAction: Equatable {
    case dismiss
  }

  public var body: some Reducer<State, Action> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .binding:
        return .none
      case let .view(viewAction):
        return handleViewAction(state: &state, action: viewAction)
      case .filter(.presented(.applyTapped)):
        if let filter = state.filter {
          state.appliedFilter = filter
        }
        state.filter = nil
        return .none
      case .filter(.presented(.dismissTapped)), .filter(.dismiss):
        state.filter = nil
        return .none
      case .filter:
        return .none
      case .delegate:
        return .none
      }
    }
    .ifLet(\.$filter, action: \.filter) {
      ClassMemberFilterFeature()
    }
  }
}

#if DEBUG
  public extension ClassMemberFeature.State {
    static func preview(room: ClassRoom) -> Self {
      Self(
        room: room,
        members: [
          ClassMember(id: 1, name: "김선생", isOwner: true),
          ClassMember(id: 2, name: "공은지"),
          ClassMember(id: 3, name: "권동현"),
          ClassMember(id: 4, name: "김민지"),
          ClassMember(id: 5, name: "천다올"),
          ClassMember(id: 6, name: "유시영"),
          ClassMember(id: 7, name: "주천수"),
          ClassMember(id: 8, name: "김예은"),
          ClassMember(id: 9, name: "서원지"),
          ClassMember(id: 10, name: "현준혁"),
        ]
      )
    }
  }
#endif

extension ClassMemberFeature {
  private func handleViewAction(state: inout State, action: View) -> Effect<Action> {
    switch action {
    case .backTapped:
      return .send(.delegate(.dismiss))
    case .filterTapped:
      state.filter = state.appliedFilter
      return .none
    case let .removeTapped(id):
      // Member removal requires a server mutation. Keep this action inert until that API exists.
      _ = id
      return .none
    }
  }
}

@Reducer
public struct ClassMemberFilterFeature {
  @ObservableState
  public struct State: Equatable {
    public var participation: ClassMemberParticipation = .all
    public var completion: ClassMemberCompletion = .all
    public var attendance: ClassMemberAttendance = .all
    public var sort: ClassMemberSort = .name

    public init() {}
  }

  public enum Action: Equatable {
    case participationSelected(ClassMemberParticipation)
    case completionSelected(ClassMemberCompletion)
    case attendanceSelected(ClassMemberAttendance)
    case sortSelected(ClassMemberSort)
    case applyTapped
    case dismissTapped
  }

  public init() {}

  public var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case let .participationSelected(value):
        guard value == .all else { return .none }
        state.participation = value
      case let .completionSelected(value):
        guard value == .all else { return .none }
        state.completion = value
      case let .attendanceSelected(value):
        guard value == .all else { return .none }
        state.attendance = value
      case let .sortSelected(value):
        guard value == .name else { return .none }
        state.sort = value
      case .applyTapped, .dismissTapped:
        break
      }
      return .none
    }
  }
}
