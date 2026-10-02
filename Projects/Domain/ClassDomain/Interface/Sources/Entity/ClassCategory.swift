public enum ClassCategory: String, CaseIterable, Equatable, Sendable {
  case philosophy
  case society
  case literature
  case science
  case art
  case history

  public var title: String {
    switch self {
    case .philosophy: "철학"
    case .society: "사회"
    case .literature: "문학"
    case .science: "과학"
    case .art: "예술"
    case .history: "역사"
    }
  }
}
