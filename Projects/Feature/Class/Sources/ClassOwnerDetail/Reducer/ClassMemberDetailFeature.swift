import ClassDomainInterface
import ComposableArchitecture

@Reducer
public struct ClassMemberDetailFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public let room: ClassRoom
    public let member: ClassOwnerMember
    public let activity: Activity?

    public struct Activity: Equatable, Sendable {
      public let initialStance: String
      public let finalStance: String
      public let commentCount: Int
      public let replyCount: Int
      public let receivedLikeCount: Int
      public let comment: String?
      public let commentOpinion: ClassOwnerOpinion?
      public let reply: String?
      public let feedback: String?

      public var changedStance: Bool {
        initialStance != finalStance
      }

      public init(
        initialStance: String,
        finalStance: String,
        commentCount: Int,
        replyCount: Int,
        receivedLikeCount: Int,
        comment: String? = nil,
        commentOpinion: ClassOwnerOpinion? = nil,
        reply: String? = nil,
        feedback: String? = nil
      ) {
        self.initialStance = initialStance
        self.finalStance = finalStance
        self.commentCount = commentCount
        self.replyCount = replyCount
        self.receivedLikeCount = receivedLikeCount
        self.comment = comment
        self.commentOpinion = commentOpinion
        self.reply = reply
        self.feedback = feedback
      }
    }

    public init(
      room: ClassRoom,
      member: ClassOwnerMember,
      activity: Activity? = nil
    ) {
      self.room = room
      self.member = member
      self.activity = activity
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
    case feedbackTapped
  }

  @CasePathable
  public enum DelegateAction: Equatable {
    case dismiss
    case commentSelected(ClassOwnerOpinion)
    case feedbackSelected
  }

  public var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case let .view(viewAction):
        switch viewAction {
        case .backTapped:
          return .send(.delegate(.dismiss))
        case .commentTapped:
          guard let opinion = state.activity?.commentOpinion else { return .none }
          return .send(.delegate(.commentSelected(opinion)))
        case .feedbackTapped:
          return .send(.delegate(.feedbackSelected))
        }
      case .delegate:
        return .none
      }
    }
  }
}
