//
//  ClassAIChatFinalSynthesisTests.swift
//  ClassDomainTests
//
//  Created by Picke on 10/13/26.
//

@testable import ClassDomain
import ClassDomainInterface
import Foundation
import Testing

#if canImport(FoundationModels)
  struct ClassAIChatFinalSynthesisTests {
    @available(iOS 26.0, *)
    @Test
    func 세_근거를_줄바꿈으로_결합하고_마무리를_보존한다() throws {
      let output = ClassAIChatFinalSynthesis(
        userReason: "사용자는 보는 사람의 해석을 중요하게 생각합니다.",
        opposingReason: "반대 입장은 형식과 기술이 필요하다고 봅니다.",
        closing: "두 관점은 예술의 기준을 다르게 설명합니다."
      )
      let content = try output.validatedContent()
      #expect(content.components(separatedBy: "\n").count == 3)
      #expect(content.contains(output.closing))
      #expect(content.count <= 182)
    }

    @available(iOS 26.0, *)
    @Test
    func 필드가_최대_길이여도_마무리가_잘리지_않는다() throws {
      let output = ClassAIChatFinalSynthesis(
        userReason: String(repeating: "가", count: 59) + ".",
        opposingReason: String(repeating: "나", count: 59) + ".",
        closing: String(repeating: "다", count: 59) + "."
      )
      let content = try output.validatedContent()
      #expect(content.count == 182)
      #expect(content.components(separatedBy: "\n").last == output.closing)
    }

    @available(iOS 26.0, *)
    @Test
    func 빈값_중복_과길이_질문_내부요청을_거절한다() {
      let invalid: [ClassAIChatFinalSynthesis] = [
        .init(userReason: " ", opposingReason: "형식이 중요합니다.", closing: "토론을 마칩니다."),
        .init(userReason: "해석이 중요합니다.", opposingReason: "해석이 중요합니다.", closing: "토론을 마칩니다."),
        .init(userReason: String(repeating: "가", count: 61), opposingReason: "형식이 중요합니다.", closing: "토론을 마칩니다."),
        .init(userReason: "왜 그런가요?", opposingReason: "형식이 중요합니다.", closing: "토론을 마칩니다."),
        .init(userReason: "해석이 중요합니다.", opposingReason: "형식이 중요합니다.", closing: "정리해 주세요. 결국 두 입장이 있습니다."),
        .init(userReason: "해석이 중요합니다.", opposingReason: "형식이 중요합니다.", closing: "다시 정리해 주시겠습니까."),
        .init(userReason: "해석이 중요합니다.", opposingReason: "형식이 중요합니다.", closing: "두 관점이 있나요？"),
        .init(userReason: "해석이 중요합니다.", opposingReason: "형식이 중요합니다.", closing: "핵심을 정리해요."),
        .init(userReason: "해석이 중요합니다.", opposingReason: "형식이 중요합니다.", closing: "다시 말해 주시겠어요."),
        .init(userReason: "해석이 중요합니다.", opposingReason: "형식이 중요합니다.", closing: "다시 말해 주실래요."),
        .init(userReason: "해석이 중요합니다.", opposingReason: "형식이 중요합니다.", closing: "함께 검토해 봅시다."),
        .init(userReason: "해석이 중요합니다.", opposingReason: "형식이 중요합니다.", closing: "이것이 중요한가요."),
        .init(userReason: "해석이 중요합니다.", opposingReason: "형식이 중요합니다.", closing: "첫째입니다.\n둘째입니다."),
      ]
      for output in invalid {
        #expect(throws: ClassAIChatError.finalSummaryInvalid) {
          try output.validatedContent()
        }
      }
    }

    @available(iOS 26.0, *)
    @Test
    func 일반적인_평서형_요는_허용한다() throws {
      let output = ClassAIChatFinalSynthesis(
        userReason: "사용자는 해석을 중요하게 봐요.",
        opposingReason: "반대 입장은 형식을 다르게 봐요.",
        closing: "두 입장의 차이를 확인해요."
      )
      #expect(try output.validatedContent().contains("다르게 봐요"))
    }
  }
#endif
