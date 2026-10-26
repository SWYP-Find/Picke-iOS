public enum ClassroomAPI {
  case classes
  case detail(classID: Int)
  case joinPreview
  case join
  case leave(classID: Int)

  public var description: String {
    switch self {
    case .classes: return "classes"
    case let .detail(id): return "classes/\(id)"
    case .joinPreview: return "classes/join/preview"
    case .join: return "classes/join"
    case let .leave(id): return "classes/\(id)/members/me"
    }
  }
}
