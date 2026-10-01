import ClassDomainInterface
import ComposableArchitecture

@Reducer
public struct ClassMemberDetailFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public let room: ClassRoom
    public let memberName: String
    public let participationRate: String
    public let commentCount: Int
    public let replyCount: Int
    public let receivedLikeCount: Int

    public init(
      room: ClassRoom,
      memberName: String = "플라톤",
      participationRate: String = "59.5%",
      commentCount: Int = 1,
      replyCount: Int = 12,
      receivedLikeCount: Int = 8
    ) {
      self.room = room
      self.memberName = memberName
      self.participationRate = participationRate
      self.commentCount = commentCount
      self.replyCount = replyCount
      self.receivedLikeCount = receivedLikeCount
    }
  }

  public enum Action: ViewAction {
    case view(View)
    case delegate(DelegateAction)
  }

  @CasePathable
  public enum View: Equatable {
    case backTapped
    case commentTapped
    case replyTapped
    case feedbackTapped
  }

  @CasePathable
  public enum DelegateAction: Equatable {
    case dismiss
    case commentSelected
    case replySelected
    case feedbackSelected
  }

  public var body: some Reducer<State, Action> {
    Reduce { _, action in
      switch action {
      case let .view(viewAction):
        switch viewAction {
        case .backTapped:
          return .send(.delegate(.dismiss))
        case .commentTapped:
          return .send(.delegate(.commentSelected))
        case .replyTapped:
          return .send(.delegate(.replySelected))
        case .feedbackTapped:
          return .send(.delegate(.feedbackSelected))
        }
      case .delegate:
        return .none
      }
    }
  }
}
