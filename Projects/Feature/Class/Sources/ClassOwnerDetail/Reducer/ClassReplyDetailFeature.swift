import ClassDomainInterface
import ComposableArchitecture

@Reducer
public struct ClassReplyDetailFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public let room: ClassRoom
    public let replies: [Reply]

    public struct Reply: Equatable, Identifiable, Sendable {
      public let id: Int
      public let author: String
      public let body: String
      public let date: String

      public init(id: Int, author: String, body: String, date: String) {
        self.id = id
        self.author = author
        self.body = body
        self.date = date
      }
    }

    public init(room: ClassRoom, replies: [Reply]? = nil) {
      self.room = room
      self.replies = replies ?? Reply.mocks
    }
  }

  public enum Action: ViewAction {
    case view(View)
    case delegate(DelegateAction)
  }

  @CasePathable
  public enum View: Equatable {
    case backTapped
  }

  @CasePathable
  public enum DelegateAction: Equatable {
    case dismiss
  }

  public var body: some Reducer<State, Action> {
    Reduce { _, action in
      switch action {
      case .view(.backTapped):
        return .send(.delegate(.dismiss))
      case .delegate:
        return .none
      }
    }
  }
}

private extension ClassReplyDetailFeature.State.Reply {
  static let mocks = [
    Self(id: 1, author: "김민지", body: "피해자 보호를 위한 기준도 함께 필요하지 않을까요?", date: "26.09.23. 14:02"),
    Self(id: 2, author: "플라톤", body: "교육과 보호도 함께 필요하다고 생각해요.", date: "26.09.23. 14:02"),
    Self(id: 3, author: "이도윤", body: "처벌만으로는 문제를 해결하기 어렵다고 느꼈어요.", date: "26.09.23. 14:03"),
  ]
}
