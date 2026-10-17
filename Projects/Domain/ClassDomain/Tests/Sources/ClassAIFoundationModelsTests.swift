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
          let schemaTokens = try await model.tokenCount(for: ClassAIChatFinalSynthesis.generationSchema)
          let reserve = 768 + 128
          audit += "; instructionTokens=\(instructionTokens); exactPromptTokens=\(exactPromptTokens); schemaTokens=\(schemaTokens); outputAndHeadroomReserve=\(reserve); contextSize=\(model.contextSize); retainedTranscriptTokens=unavailable"
        }
        audit += "\nprompts=\(prompts)\nroundReplies=\(replies)"
        let attachment = XCTAttachment(string: audit)
        attachment.name = "합성 토론 3턴·재진입 관측"
        attachment.lifetime = .keepAlways
        add(attachment)

        XCTAssertEqual(replies.count, 3)
        XCTAssertTrue(replies.allSatisfy { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
        XCTAssertFalse(third.contains("?"))
        XCTAssertFalse(third.contains("정리해 주세요"))
        XCTAssertFalse(third.contains("주시겠습니까"))
        XCTAssertTrue(third.contains("해석"), "마지막 사용자 근거를 반영해야 합니다.")
        XCTAssertTrue(third.contains("형식") || third.contains("기술"), "반대 입장의 근거를 반영해야 합니다.")
      } catch {
        await client.end(id)
        throw error
      }
    }

    @available(iOS 26.0, *)
    func testRejectedFinalCanRestoreTranscriptAndManuallyRetryOnDevice() async throws {
      guard ProcessInfo.processInfo.environment["PICKE_CLASS_FOUNDATION_AUDIT"] == "1" else {
        throw XCTSkip("실기 Foundation Models 감사는 명시적으로 켠 경우에만 실행합니다.")
      }
      let model = SystemLanguageModel.default
      guard case .available = model.availability, model.supportsLocale(Locale(identifier: "ko_KR")) else {
        throw XCTSkip("기기에서 한국어 Foundation Models를 사용할 수 없습니다.")
      }

      let session = LanguageModelSession(model: model, instructions: "한국어로 짧게 답하세요.")
      _ = try await session.respond(to: "예술에는 형식도 중요할까요?")
      let beforeFinal = Array(session.transcript)
      XCTAssertFalse(beforeFinal.isEmpty)

      _ = try await session.respond(
        to: "두 입장의 근거를 간단히 마무리하세요.",
        generating: ClassAIChatFinalSynthesis.self,
        options: GenerationOptions(maximumResponseTokens: 768)
      )
      let rejected = ClassAIChatFinalSynthesis(
        userReason: "사용자는 해석이 중요하다고 봅니다.",
        opposingReason: "반대 입장은 형식을 강조합니다.",
        closing: "다시 정리해 주세요. 두 관점이 있습니다."
      )
      XCTAssertThrowsError(try rejected.validatedContent()) { error in
        XCTAssertEqual(error as? ClassAIChatError, .finalSummaryInvalid)
      }

      let stale = LanguageModelSession(model: model, instructions: "다른 대화")
      XCTAssertThrowsError(try ClassAIChatFoundationEngine.restoredSession(
        current: stale,
        captured: session,
        model: model,
        entries: beforeFinal
      )) { error in
        XCTAssertTrue(error is CancellationError)
      }
      let restored = try ClassAIChatFoundationEngine.restoredSession(
        current: session,
        captured: session,
        model: model,
        entries: beforeFinal
      )
      XCTAssertEqual(restored.transcript, Transcript(entries: beforeFinal))
      let retry = try await restored.respond(to: "형식과 해석의 차이를 한 문장으로 말해 주세요.")
      XCTAssertFalse(retry.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
      let afterRetry = Array(restored.transcript)
      let addedPrompts = afterRetry.dropFirst(beforeFinal.count).filter { entry in
        if case .prompt = entry {
          return true
        }
        return false
      }
      XCTAssertEqual(addedPrompts.count, 1)
    }
  #endif
}
