//
//  ClassAIFoundationModelsTests.swift
//  ClassDomainTests
//
//  Created by Picke on 10/11/26.
//

@testable import ClassDomain
import ClassDomainInterface
import Foundation
import XCTest

#if canImport(FoundationModels)
  import FoundationModels
#endif

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

  #if canImport(FoundationModels)
    @available(iOS 26.0, *)
    func testSyntheticThreeRoundsAndReentryOnDevice() async throws {
      guard ProcessInfo.processInfo.environment["PICKE_CLASS_FOUNDATION_AUDIT"] == "1" else {
        throw XCTSkip("실기 Foundation Models 감사는 명시적으로 켠 경우에만 실행합니다.")
      }
      let model = SystemLanguageModel.default
      guard case .available = model.availability, model.supportsLocale(Locale(identifier: "ko_KR")) else {
        throw XCTSkip("기기에서 한국어 Foundation Models를 사용할 수 없습니다.")
      }

      let id = UUID()
      let context = ClassAIChatContext(
        question: "평범한 물건도 예술이 될 수 있을까?",
        selectedStance: "새로운 의미가 있으면 예술이다",
        opponentStance: "형식과 기술도 필요하다",
        opponentPhilosopherName: nil
      )
      let prompts = [
        "새로운 의미를 발견하게 하면 평범한 물건도 예술이라고 생각해요.",
        "진짜? 왜 그렇게 생각해요?",
        "형식뿐 아니라 보는 사람의 해석도 중요하다는 점을 정리하고 싶어요.",
      ]
      let client = ClassAIChatUseCaseDependency.liveValue
      var replies: [String] = []
      do {
        try await client.start(id, context)
        let first = try await client.respond(id, prompts[0], isFinalRound: false)
        let second = try await client.respond(id, prompts[1], isFinalRound: false)
        replies = [first, second]
        await client.end(id)

        let prior: [ClassAIChatMessage] = [
          .init(speaker: .user, text: prompts[0]),
          .init(speaker: .opponent, text: first),
          .init(speaker: .user, text: prompts[1]),
          .init(speaker: .opponent, text: second),
        ]
        let resumed = ClassAIChatContext(
          question: context.question,
          selectedStance: context.selectedStance,
          opponentStance: context.opponentStance,
          opponentPhilosopherName: nil,
          priorMessages: prior
        )
        try await client.start(id, resumed)
        let third = try await client.respond(id, prompts[2], isFinalRound: true)
        replies.append(third)
        await client.end(id)

        let limit = if #available(iOS 26.4, *) {
          1440
        } else {
          720
        }
        var history = ClassAIChatHistory()
        history.prepare(id: id, messages: prior, maximumCharacters: limit)
        let payload = history.pendingPayload(id: id) ?? ""
        let exactPrompt = history.prompt(id: id, userText: prompts[2], isFinalRound: true)
        var audit = "OS=\(ProcessInfo.processInfo.operatingSystemVersionString); available=true; historyCharacters=\(payload.count)"
        if #available(iOS 26.4, *) {
          let instructionTokens = try await model
            .tokenCount(for: Instructions(ClassAIChatInstructions.make(context: resumed)))
          let exactPromptTokens = try await model.tokenCount(for: Prompt(exactPrompt))
          let reserve = 384 + 128
          audit += "; instructionTokens=\(instructionTokens); exactPromptTokens=\(exactPromptTokens); outputAndHeadroomReserve=\(reserve); contextSize=\(model.contextSize); retainedTranscriptTokens=unavailable"
        }
        audit += "\nprompts=\(prompts)\nroundReplies=\(replies)"
        let attachment = XCTAttachment(string: audit)
        attachment.name = "합성 토론 3턴·재진입 관측"
        attachment.lifetime = .keepAlways
        add(attachment)

        XCTAssertEqual(replies.count, 3)
        XCTAssertTrue(replies.allSatisfy { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
      } catch {
        await client.end(id)
        throw error
      }
    }
  #endif
}
