public enum ClassBattleRecommendationAPI {
  case recommendations

  public var description: String {
    switch self {
    case .recommendations: return "class-battle-recommendations"
    }
  }
}
