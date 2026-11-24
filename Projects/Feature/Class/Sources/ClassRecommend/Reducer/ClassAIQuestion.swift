//
//  ClassAIQuestion.swift
//  Class
//
//  Created by Picke on 10/11/26.
//

import ClassDomainInterface
import Foundation

public struct ClassAIQuestion: Equatable, Identifiable, Sendable {
  public let id: Int
  public let category: String
  public let title: String
  public let summary: String
  public let optionATitle: String
  public let optionADescription: String
  public let philosopherAName: String?
  public let optionBTitle: String
  public let optionBDescription: String
  public let philosopherBName: String?

  public init(
    id: Int,
    category: String,
    title: String,
    summary: String,
    optionATitle: String,
    optionADescription: String,
    philosopherAName: String? = nil,
    optionBTitle: String,
    optionBDescription: String,
    philosopherBName: String? = nil
  ) {
    self.id = id
    self.category = category
    self.title = title
    self.summary = summary
    self.optionATitle = optionATitle
    self.optionADescription = optionADescription
    self.philosopherAName = philosopherAName
    self.optionBTitle = optionBTitle
    self.optionBDescription = optionBDescription
    self.philosopherBName = philosopherBName
  }

  public init?(candidate: ClassTopicCandidate) {
    guard candidate.options.count == 2 else { return nil }
    self.init(
      id: candidate.id,
      category: candidate.category,
      title: candidate.question,
      summary: candidate.description,
      optionATitle: candidate.options[0].label,
      optionADescription: candidate.options[0].rationale,
      philosopherAName: candidate.options[0].philosopher,
      optionBTitle: candidate.options[1].label,
      optionBDescription: candidate.options[1].rationale,
      philosopherBName: candidate.options[1].philosopher
    )
  }

  public init?(version: ClassTopicVersion) {
    guard let first = version.options.first(where: { $0.position == "A" }),
          let second = version.options.first(where: { $0.position == "B" })
    else { return nil }
    self.init(
      id: version.id,
      category: version.category,
      title: version.question,
      summary: version.description,
      optionATitle: first.label,
      optionADescription: first.rationale,
      philosopherAName: first.philosopherName,
      optionBTitle: second.label,
      optionBDescription: second.rationale,
      philosopherBName: second.philosopherName
    )
  }

  public static let examples: [Self] = [
    .init(
      id: 1,
      category: "사회",
      title: "슬픔을 드러내지 않은 뫼르소를 비난할 수 있을까?",
      summary: "감정을 표현하지 않는 태도를 도덕적으로 판단할 수 있는지 이야기해요.",
      optionATitle: "비난할 수 있다",
      optionADescription: "사회적 공감도 중요하다",
      philosopherAName: "사르트르",
      optionBTitle: "유지해야 한다",
      optionBDescription: "연령과 교정 가능성 고려",
      philosopherBName: "플라톤"
    ),
    .init(
      id: 2,
      category: "사회",
      title: "재판에서 삶의 태도까지 판단 근거가 되어도 될까?",
      summary: "뫼르소의 범죄와 무관한 태도가 재판에 영향을 주는 것이 정당할까요?",
      optionATitle: "고려해도 된다",
      optionADescription: "인물의 태도도 판단의 일부다",
      optionBTitle: "범죄만 봐야 한다",
      optionBDescription: "행위와 증거만 판단해야 한다"
    ),
    .init(
      id: 3,
      category: "철학",
      title: "삶에 정해진 의미가 없다는 태도는 자유일까?",
      summary: "뫼르소의 삶의 태도를 개인의 자유와 책임이라는 관점에서 생각해봐요.",
      optionATitle: "개인의 자유다",
      optionADescription: "의미는 스스로 정할 수 있다",
      optionBTitle: "무책임한 태도다",
      optionBDescription: "타인과 사회에 대한 책임이 있다"
    ),
    .init(
      id: 4,
      category: "사회",
      title: "사회가 기대하는 감정을 따라야 할까?",
      summary: "감정 표현에 관한 사회적 기대와 개인의 차이를 토론해요.",
      optionATitle: "따라야 한다",
      optionADescription: "함께 살아가는 약속이다",
      optionBTitle: "그럴 필요 없다",
      optionBDescription: "표현은 개인의 선택이다"
    ),
    .init(
      id: 5,
      category: "문학",
      title: "주인공의 침묵은 무관심을 뜻할까?",
      summary: "인물의 행동과 내면 사이의 거리를 살펴봐요.",
      optionATitle: "무관심이다",
      optionADescription: "행동에 마음이 드러난다",
      optionBTitle: "단정할 수 없다",
      optionBDescription: "침묵에도 여러 이유가 있다"
    ),
    .init(
      id: 6,
      category: "도덕",
      title: "솔직한 마음보다 예의가 먼저일까?",
      summary: "솔직함과 관계를 지키는 태도 사이에서 생각해봐요.",
      optionATitle: "예의가 먼저다",
      optionADescription: "상대를 배려해야 한다",
      optionBTitle: "솔직함이 먼저다",
      optionBDescription: "진심을 숨기지 않아야 한다"
    ),
    .init(
      id: 7,
      category: "사회",
      title: "다른 선택을 한 사람을 사회가 이해해야 할까?",
      summary: "다름을 받아들이는 사회의 기준을 토론해요.",
      optionATitle: "이해해야 한다",
      optionADescription: "다양성을 존중해야 한다",
      optionBTitle: "기준이 필요하다",
      optionBDescription: "공동체의 규범도 중요하다"
    ),
    .init(
      id: 8,
      category: "철학",
      title: "인생의 의미는 스스로 정할 수 있을까?",
      summary: "의미를 찾는 과정에 나와 사회가 미치는 영향을 생각해봐요.",
      optionATitle: "스스로 정한다",
      optionADescription: "삶의 주인은 나다",
      optionBTitle: "함께 만들어진다",
      optionBDescription: "관계 속에서 의미가 생긴다"
    ),
  ]
}
