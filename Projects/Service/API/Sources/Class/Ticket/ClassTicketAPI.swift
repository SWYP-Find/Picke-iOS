public enum ClassTicketAPI {
  case preview
  case register
  case me

  public var description: String {
    switch self {
    case .preview: return "class-tickets/preview"
    case .register: return "class-tickets/register"
    case .me: return "class-tickets/me"
    }
  }
}
