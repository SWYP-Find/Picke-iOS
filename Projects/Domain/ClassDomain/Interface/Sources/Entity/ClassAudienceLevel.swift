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
}
