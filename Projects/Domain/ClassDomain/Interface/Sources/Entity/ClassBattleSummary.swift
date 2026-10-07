import Foundation

public struct ClassBattleSummary: Equatable, Identifiable, Sendable {
  public let id: Int
  public let title: String
  public let summary: String
  public let thumbnailURL: URL?
  public let philosopherA: String
  public let optionATitle: String
  public let philosopherAImageURL: URL?
  public let philosopherB: String
  public let optionBTitle: String
  public let philosopherBImageURL: URL?
  public let category: ClassCategory
  public let level: ClassAudienceLevel
  public let audioDuration: Int
  public let viewCount: Int

  public init(
    id: Int,
    title: String,
    summary: String,
    thumbnailURL: URL? = nil,
    philosopherA: String,
    optionATitle: String,
    philosopherAImageURL: URL? = nil,
    philosopherB: String,
    optionBTitle: String,
    philosopherBImageURL: URL? = nil,
    category: ClassCategory,
    level: ClassAudienceLevel,
    audioDuration: Int,
    viewCount: Int
  ) {
    self.id = id
    self.title = title
    self.summary = summary
    self.thumbnailURL = thumbnailURL
    self.philosopherA = philosopherA
    self.optionATitle = optionATitle
    self.philosopherAImageURL = philosopherAImageURL
    self.philosopherB = philosopherB
    self.optionBTitle = optionBTitle
    self.philosopherBImageURL = philosopherBImageURL
    self.category = category
    self.level = level
    self.audioDuration = audioDuration
    self.viewCount = viewCount
  }

  public var durationMinutes: Int {
    max(1, audioDuration / 60)
  }
}

public extension ClassBattleSummary {
  static let mocks: [ClassBattleSummary] = [
    .init(
      id: 101,
      title: "촉법소년 연령을 낮춰야 할까?",
      summary: "청소년 범죄와 보호의 균형을 이야기해요.",
      philosopherA: "엄격한 처벌",
      optionATitle: "연령을 낮춰야 한다",
      philosopherB: "회복적 보호",
      optionBTitle: "현행 연령을 유지한다",
      category: .society,
      level: .middle,
      audioDuration: 5 * 60,
      viewCount: 726
    ),
    .init(
      id: 102,
      title: "뒤샹의 변기, 예술인가 도발인가",
      summary: "예술의 경계를 함께 생각해요.",
      philosopherA: "예술의 확장",
      optionATitle: "예술이다",
      philosopherB: "전통적 관점",
      optionBTitle: "도발이다",
      category: .art,
      level: .high,
      audioDuration: 6 * 60,
      viewCount: 902
    ),
    .init(
      id: 103,
      title: "인공지능의 결정에 책임을 물을 수 있을까?",
      summary: "기술과 인간의 책임을 함께 생각해요.",
      philosopherA: "개발자의 책임",
      optionATitle: "만든 사람이 책임져야 한다",
      philosopherB: "사용자의 책임",
      optionBTitle: "사용한 사람이 책임져야 한다",
      category: .society,
      level: .adult,
      audioDuration: 7 * 60,
      viewCount: 318
    ),
    .init(
      id: 104,
      title: "인간은 본래 선한가?",
      summary: "인간의 본성과 선택을 함께 생각해요.",
      philosopherA: "성선설",
      optionATitle: "인간은 본래 선하다",
      philosopherB: "성악설",
      optionBTitle: "인간은 본래 악하다",
      category: .philosophy,
      level: .high,
      audioDuration: 6 * 60,
      viewCount: 512
    ),
    .init(
      id: 105,
      title: "무지는 죄인가?",
      summary: "알지 못한 일에 대한 책임을 토론해요.",
      philosopherA: "책임의 관점",
      optionATitle: "무지도 책임져야 한다",
      philosopherB: "이해의 관점",
      optionBTitle: "모르는 것만으로는 죄가 아니다",
      category: .literature,
      level: .middle,
      audioDuration: 5 * 60,
      viewCount: 441
    ),
  ]
}
