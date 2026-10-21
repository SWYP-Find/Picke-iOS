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

  func toDomain() throws -> ClassBattleSummary {
    guard let category = ClassCategory.allCases.first(where: { $0.title == self.category }) else {
      throw ClassError.unknown("알 수 없는 배틀 카테고리: \(category)")
    }
    let level: ClassAudienceLevel
    switch difficulty {
    case "BEGINNER": level = .middle
    case "INTERMEDIATE": level = .high
    case "ADVANCED": level = .adult
    default: throw ClassError.unknown("알 수 없는 배틀 수준: \(difficulty)")
    }
    guard let optionA = options.first(where: { $0.position == "A" }),
          let optionB = options.first(where: { $0.position == "B" })
    else {
      throw ClassError.unknown("배틀의 A/B 선택지가 누락됐습니다.")
    }
    return ClassBattleSummary(
      id: battleId,
      title: title,
      summary: summary ?? "",
      thumbnailURL: thumbnailUrl.flatMap(URL.init(string:)),
      philosopherA: optionA.representative ?? "",
      optionATitle: optionA.title,
      optionADescription: optionA.stance,
      philosopherAImageURL: optionA.imageUrl.flatMap(URL.init(string:)),
      philosopherB: optionB.representative ?? "",
      optionBTitle: optionB.title,
      optionBDescription: optionB.stance,
      philosopherBImageURL: optionB.imageUrl.flatMap(URL.init(string:)),
      category: category,
      level: level,
      audioDuration: audioDuration ?? 0,
      viewCount: 0
    )
  }
}

struct ClassBattleRecommendationOptionDTO: Decodable, Sendable {
  let optionId: Int
  let position: String
  let title: String
  let stance: String?
  let representative: String?
  let imageUrl: String?
}
