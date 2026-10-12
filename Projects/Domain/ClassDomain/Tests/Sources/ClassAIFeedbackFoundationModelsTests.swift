//
//  ClassAIFeedbackFoundationModelsTests.swift
//  ClassDomainTests
//
//  Created by Picke on 10/12/26.
//

@testable import ClassDomain
import ClassDomainInterface
import Foundation
import XCTest

final class ClassAIFeedbackFoundationModelsTests: XCTestCase {
  #if canImport(FoundationModels)
    @available(iOS 26.0, *)
    func testGeneratedFieldLengthValidationKeepsOnlyOverlengthRetryable() throws {
      XCTAssertEqual(try ClassAIFeedbackFoundationEngine.validated("  토론  ", maximum: 2), "토론")
      XCTAssertThrowsError(try ClassAIFeedbackFoundationEngine.validated("가나다", maximum: 2)) { error in
        XCTAssertEqual(error as? ClassAIFeedbackError, .temporarilyUnavailable)
        XCTAssertTrue((error as? ClassAIFeedbackError)?.isRetryable == true)
      }
      XCTAssertThrowsError(try ClassAIFeedbackFoundationEngine.validated("   ", maximum: 2)) { error in
        XCTAssertEqual(error as? ClassAIFeedbackError, .generationFailed)
        XCTAssertFalse((error as? ClassAIFeedbackError)?.isRetryable == true)
      }
    }
  #endif

  func testMaximumBudgetOnEligibleDevice() async throws {
    guard ProcessInfo.processInfo.environment["PICKE_CLASS_FOUNDATION_AUDIT"] == "1" else {
      throw XCTSkip("실기 Foundation Models 검증은 PICKE_CLASS_FOUNDATION_AUDIT=1에서만 실행합니다.")
    }
    let room = ClassRoom.mockClosedSociety
    let report = ClassReport(
      texts: MockClassReport.figma.texts,
      myOpinions: Array(repeating: String(repeating: "토론 근거를 구체적으로 확인했습니다. ", count: 12), count: 4),
      initialVoteLeading: 0.64,
      finalVoteLeading: 0.50,
      layout: .summary
    )
    let context = try ClassAIFeedbackContext.personal(room: room, report: report, isOwner: false)
    let client = ClassAIFeedbackUseCaseDependency.liveValue
    do {
      let result = try await client.generate(context: context)
      let attachment =
        XCTAttachment(
          string: "OS \(ProcessInfo.processInfo.operatingSystemVersionString), evidence \(context.writtenEvidence.count), result \(result)"
        )
      attachment.name = "Class AI feedback 실제 모델 및 예산"
      attachment.lifetime = .keepAlways
      add(attachment)
      guard case let .personal(personal) = result else {
        XCTFail("개인 입력에 개인 피드백 결과가 필요합니다.")
        return
      }
      XCTAssertEqual(personal.points.count, 3)
      XCTAssertFalse(personal.summaryDetail.isEmpty)
    } catch let error as ClassAIFeedbackError where error.isUnavailable || error == .modelNotReady {
      throw XCTSkip("기기에서 한국어 Foundation Models를 사용할 수 없습니다: \(error)")
    }
  }
}
