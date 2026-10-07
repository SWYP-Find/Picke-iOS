public enum ClassAudienceLevel: String, CaseIterable, Equatable, Sendable {
  case middle
  case high
  case adult

  public var title: String {
    switch self {
    case .middle: "중등"
    case .high: "고등"
    case .adult: "성인"
    }
  }

  public var topicTitle: String {
    switch self {
    case .middle: "초급"
    case .high: "중급"
    case .adult: "고급"
    }
  }
}
