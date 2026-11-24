//
//  ClassAIChatFinalSynthesis.swift
//  ClassDomain
//
//  Created by Picke on 10/13/26.
//

import ClassDomainInterface
import Foundation

#if canImport(FoundationModels)
  import FoundationModels

  @available(iOS 26.0, *)
  @Generable
  struct ClassAIChatFinalSynthesis {
    @Guide(description: "사용자의 가장 최근 근거를 정확히 반영한 한국어 평서문 한 문장. 60자 이하. 질문이나 요청을 하지 마세요.")
    var userReason: String

    @Guide(description: "반대 입장의 근거를 공정하게 설명하는 한국어 평서문 한 문장. 60자 이하. 질문이나 요청을 하지 마세요.")
    var opposingReason: String

    @Guide(description: "두 입장을 새 논점 없이 마무리하는 한국어 평서문 한 문장. 60자 이하. 질문이나 요청을 하지 마세요.")
    var closing: String

    func validatedContent() throws -> String {
      let fields = [userReason, opposingReason, closing]
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      guard fields.allSatisfy(Self.isDeclarativeSentence),
            Set(fields).count == fields.count
      else {
        throw ClassAIChatError.finalSummaryInvalid
      }
      let content = fields.joined(separator: "\n")
      guard content.count <= 182 else { throw ClassAIChatError.finalSummaryInvalid }
      return content
    }

    private static func isDeclarativeSentence(_ text: String) -> Bool {
      guard !text.isEmpty, text.count <= 60 else { return false }
      let body = text.hasSuffix(".") ? String(text.dropLast()) : text
      guard !body.isEmpty,
            !body.contains(where: { ".?!？！。…\n\r".contains($0) })
      else {
        return false
      }
      let requests = [
        "주세요", "주십시오", "보세요", "해보세요", "하시겠습니까", "습니까", "나요", "까요",
        "정리해요", "말해요", "답해요", "정리해 보죠", "생각해 보죠",
        "주시겠어요", "주실래요", "실래요", "한가요", "인가요", "는가요", "봅시다", "합시다",
        "할래요", "는지요",
      ]
      return !requests.contains(where: body.hasSuffix)
    }
  }
#endif
