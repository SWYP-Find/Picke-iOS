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
  ] + philosophyRecommendationMocks

  /// Figma 추천 화면의 `중등 · 철학` 조건을 재현하는 목 결과.
  private static let philosophyRecommendationMocks: [ClassBattleSummary] = [
    .init(
      id: 106,
      title: "인간은 본래 선한가, 악한가?",
      summary: "인간 본성의 선악과 문명의 역할에 관한 철학적 대결!",
      philosopherA: "순자",
      optionATitle: "악하다",
      philosopherB: "노자",
      optionBTitle: "선하다",
      category: .philosophy,
      level: .middle,
      audioDuration: 5 * 60,
      viewCount: 1340
    ),
    .init(
      id: 107,
      title: "불매운동은 소비자의 권리인가?",
      summary: "기업 불매운동은 사회를 바꾸는 소비자의 권리일까, 도덕적 우월감을 위한 행동일까?",
      philosopherA: "마르크스",
      optionATitle: "소비자의 권리",
      philosopherB: "니체",
      optionBTitle: "도덕적 우월감",
      category: .philosophy,
      level: .middle,
      audioDuration: 5 * 60,
      viewCount: 1340
    ),
    .init(
      id: 108,
      title: "부모의 극단적 개입, 사랑인가 착취인가?",
      summary: "부모가 자녀의 미래를 위해 삶에 극단적으로 개입하는 것은 사랑일까, 착취일까?",
      philosopherA: "보호의 관점",
      optionATitle: "사랑이다",
      philosopherB: "자율의 관점",
      optionBTitle: "착취다",
      category: .philosophy,
      level: .middle,
      audioDuration: 5 * 60,
      viewCount: 1340
    ),
    .init(
      id: 109,
      title: "아틀란티스는 실존하는가?",
      summary: "아리스토텔레스가 증언함에도 불구하고 아틀란티스가 허구라고 단언할 수 있는가?",
      philosopherA: "실존의 관점",
      optionATitle: "실존했다",
      philosopherB: "회의의 관점",
      optionBTitle: "허구다",
      category: .philosophy,
      level: .middle,
      audioDuration: 3 * 60,
      viewCount: 1340
    ),
    .init(
      id: 110,
      title: "자유와 책임은 함께할 수 있을까?",
      summary: "자유로운 선택에 따르는 책임을 이야기해요.",
      philosopherA: "자유의 관점",
      optionATitle: "함께한다",
      philosopherB: "결정론의 관점",
      optionBTitle: "함께하기 어렵다",
      category: .philosophy,
      level: .middle,
      audioDuration: 5 * 60,
      viewCount: 1340
    ),
    .init(
      id: 111,
      title: "정의로운 결과를 위해 거짓말해도 될까?",
      summary: "진실과 결과 가운데 무엇을 우선해야 할지 토론해요.",
      philosopherA: "결과의 관점",
      optionATitle: "가능하다",
      philosopherB: "원칙의 관점",
      optionBTitle: "안 된다",
      category: .philosophy,
      level: .middle,
      audioDuration: 5 * 60,
      viewCount: 1340
    ),
    .init(
      id: 112,
      title: "행복은 스스로 선택할 수 있을까?",
      summary: "행복을 결정하는 개인과 사회의 역할을 살펴봐요.",
      philosopherA: "선택의 관점",
      optionATitle: "선택할 수 있다",
      philosopherB: "환경의 관점",
      optionBTitle: "환경에 달려 있다",
      category: .philosophy,
      level: .middle,
      audioDuration: 5 * 60,
      viewCount: 1340
    ),
    .init(
      id: 113,
      title: "규칙은 언제나 지켜야 할까?",
      summary: "공동체의 규칙과 개인의 양심 사이를 생각해요.",
      philosopherA: "질서의 관점",
      optionATitle: "지켜야 한다",
      philosopherB: "양심의 관점",
      optionBTitle: "예외가 있다",
      category: .philosophy,
      level: .middle,
      audioDuration: 5 * 60,
      viewCount: 1340
    ),
  ]
}
