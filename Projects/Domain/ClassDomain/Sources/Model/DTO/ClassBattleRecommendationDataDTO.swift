import ClassDomainInterface
import Foundation

struct ClassBattleRecommendationDataDTO: Decodable, Sendable {
  let items: [ClassBattleRecommendationItemDTO]
}

struct ClassBattleRecommendationItemDTO: Decodable, Sendable {
  let battleId: Int
  let title: String
  let summary: String?
  let thumbnailUrl: String?
  let category: String
  let difficulty: String
  let audioDuration: Int?
  let options: [ClassBattleRecommendationOptionDTO]
}

struct ClassBattleRecommendationOptionDTO: Decodable, Sendable {
  let optionId: Int
  let position: String
  let title: String
  let stance: String?
  let representative: String?
  let imageUrl: String?
}
