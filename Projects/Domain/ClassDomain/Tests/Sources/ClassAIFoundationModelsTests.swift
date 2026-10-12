//
//  ClassAIFoundationModelsTests.swift
//  ClassDomainTests
//
//  Created by Picke on 10/11/26.
//

import ClassDomain
import ClassDomainInterface
import Foundation
import XCTest

final class ClassAIFoundationModelsTests: XCTestCase {
  func testLiveModelRespondsInKoreanOnDevice() async throws {
    guard ProcessInfo.processInfo.environment["PICKE_CLASS_FOUNDATION_AUDIT"] == "1" else {
      throw XCTSkip("실기 Foundation Models 감사는 PICKE_CLASS_FOUNDATION_AUDIT=1에서만 실행합니다.")
    }

    let client = ClassAIChatUseCaseDependency.liveValue
    let conversationID = UUID()

    do {
      try await client.start(conversationID, ClassAIChatContext(
        question: "뒤샹의 변기는 예술일까?",
        selectedStance: "예술이 될 수 있다",
        opponentStance: "예술이 아니다",
        opponentPhilosopherName: "플라톤"
      ))
      let reply = try await client.respond(
        conversationID,
        "평범한 물건도 새로운 의미를 부여하면 예술이 될 수 있어요.",
        isFinalRound: false
      )
      await client.end(conversationID)

      let attachment = XCTAttachment(string: reply)
      attachment.name = "Class AI 실제 모델 응답"
      attachment.lifetime = .keepAlways
      add(attachment)

      XCTAssertFalse(reply.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
      XCTAssertTrue(
        reply.unicodeScalars.contains { (0xAC00 ... 0xD7A3).contains($0.value) },
        "모델 응답에 한글 음절이 포함되어야 합니다."
      )
    } catch {
      await client.end(conversationID)
      if let modelError = error as? ClassAIChatError,
         modelError == .unavailable || modelError == .unsupportedLanguage
         || modelError == .deviceNotEligible || modelError == .appleIntelligenceNotEnabled
         || modelError == .modelNotReady
      {
        throw XCTSkip("기기에서 한국어 Foundation Models를 사용할 수 없습니다: \(modelError.localizedDescription)")
      }
      throw error
    }
  }
}
