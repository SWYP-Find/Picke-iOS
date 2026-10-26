public enum ClassTopicDraftAPI {
  case drafts
  case detail(draftID: Int)
  case suggestions(draftID: Int)
  case selection(draftID: Int)
  case validations(draftID: Int)

  public var description: String {
    switch self {
    case .drafts: return "class-topic-drafts"
    case let .detail(id): return "class-topic-drafts/\(id)"
    case let .suggestions(id): return "class-topic-drafts/\(id)/suggestions"
    case let .selection(id): return "class-topic-drafts/\(id)/selection"
    case let .validations(id): return "class-topic-drafts/\(id)/validations"
    }
  }
}
