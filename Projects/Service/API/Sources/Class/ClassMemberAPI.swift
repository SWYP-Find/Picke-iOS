public enum ClassMemberAPI {
  case members(classID: Int)
  case me(classID: Int)
  case member(classID: Int, memberID: Int)

  public var description: String {
    switch self {
    case let .members(id): return "classes/\(id)/members"
    case let .me(id): return "classes/\(id)/members/me"
    case let .member(id, memberID): return "classes/\(id)/members/\(memberID)"
    }
  }
}
