import Foundation
import ClassDomainInterface

struct ClassBattleRecommendationQuery: Encodable, Sendable {
  let difficulty: String
  let categories: String
  let keyword: String?
}
