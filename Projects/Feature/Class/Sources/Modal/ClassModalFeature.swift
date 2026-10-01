import ComposableArchitecture

@Reducer
public struct ClassModalFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public enum Kind: Equatable {
      case nickname
      case management
      case deadline
      case code
    }

    public let kind: Kind

    public init(kind: Kind) {
      self.kind = kind
    }
  }

  public enum Action {
    case dismissTapped
  }

  public var body: some Reducer<State, Action> {
    EmptyReducer()
  }
}
