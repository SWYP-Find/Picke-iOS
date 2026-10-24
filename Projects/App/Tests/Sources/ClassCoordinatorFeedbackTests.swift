//
//  ClassCoordinatorFeedbackTests.swift
//  PickeTests
//
//  Created by Picke on 10/12/26.
//

import ComposableArchitecture
import DomainAssembly
import FeatureAssembly
import Foundation
@testable import Picke
import TCAFlow
import Testing

@MainActor
struct ClassCoordinatorFeedbackTests {
  @Test
  func 스와이프로_제거된_보고서의_AI_생성만_취소하고_남은_보고서는_완료한다() async {
    let room = ClassRoom.mockClosedSociety
    let generator = SuspendedFeedbackGenerator()
    let firstID = UUID()
    let removedID = UUID()
    var first = ClassReportFeature.State(room: room, instanceID: firstID)
    first.report = MockClassReport.figma
    first.sourceViewState = .ready
    var removed = ClassReportFeature.State(room: room, instanceID: removedID)
    removed.report = MockClassReport.figma
    removed.sourceViewState = .ready
    var state = ClassCoordinator.State()
    state.routes.push(.detail(.init(room: room)))
    state.routes.push(.report(first))
    state.routes.push(.report(removed))
    let store = TestStore(initialState: state) { ClassCoordinator() } withDependencies: {
      $0.classResultUseCase = generator
      $0.uuid = .incrementing
    }
    store.exhaustivity = .off

    await store.send(.router(.routeAction(id: 2, action: .report(.async(.generateFeedback)))))
    await generator.waitForStarts(1)
    await store.send(.router(.routeAction(id: 3, action: .report(.async(.generateFeedback)))))
    await generator.waitForStarts(2)
    await store.send(.router(.updateRoutes(Array(store.state.routes.dropLast()))))
    await generator.complete(requestID: 1, result: .personal(.fixture))
    await store.receive {
      guard case let .router(.routeAction(id: 2, action: .report(action))) = $0,
            case .inner(.feedbackResponse) = action else { return false }
      return true
    }
    await store.finish(timeout: .seconds(1))

    #expect(await generator.cancelledRequestIDs == [2])
    guard case let .report(surviving)? = store.state.routes.last?.screen else {
      Issue.record("남은 보고서 경로가 사라졌습니다.")
      return
    }
    #expect(surviving.instanceID == firstID)
    #expect(surviving.feedback == .fixture)
  }

  @Test
  func 같은_인덱스의_보고서_교체는_기존_생성을_취소하고_늦은_응답을_무시한다() async throws {
    let room = ClassRoom.mockClosedSociety
    let generator = SuspendedFeedbackGenerator()
    let originalID = UUID()
    let replacementID = UUID()
    var original = ClassReportFeature.State(room: room, instanceID: originalID)
    original.report = MockClassReport.figma
    original.sourceViewState = .ready
    var state = ClassCoordinator.State()
    state.routes.push(.detail(.init(room: room)))
    state.routes.push(.report(original))
    let store = TestStore(initialState: state) { ClassCoordinator() } withDependencies: {
      $0.classResultUseCase = generator
      $0.uuid = .incrementing
    }
    store.exhaustivity = .off

    await store.send(.router(.routeAction(id: 2, action: .report(.async(.generateFeedback)))))
    await generator.waitForStarts(1)
    guard case let .report(active)? = store.state.routes.last?.screen else {
      Issue.record("기존 보고서가 없습니다.")
      return
    }
    let requestID = try #require(active.feedbackRequestID)
    var replacementRoutes = store.state.routes
    replacementRoutes[screenAt: 2] = .report(.init(room: room, instanceID: replacementID))
    await store.send(.router(.updateRoutes(replacementRoutes)))
    await store.finish(timeout: .seconds(1))
    #expect(await generator.cancelledRequestIDs == [1])

    await store.send(.router(.routeAction(id: 2, action: .report(.inner(.feedbackResponse(
      instanceID: originalID,
      requestID: requestID,
      roomID: room.id,
      .success(.personal(.fixture)),
      wasUnknown: false
    ))))))
    guard case let .report(replacement)? = store.state.routes.last?.screen else {
      Issue.record("교체된 보고서가 없습니다.")
      return
    }
    #expect(replacement.instanceID == replacementID)
    #expect(replacement.feedback == nil)
    #expect(!replacement.isGeneratingFeedback)
  }

  @Test
  func 운영자_대시보드_교체는_두_AI_생성을_모두_취소하고_늦은_응답을_무시한다() async throws {
    let room = ClassRoom.mocks[0]
    let generator = SuspendedFeedbackGenerator()
    let originalID = UUID()
    let replacementID = UUID()
    var original = ClassOwnerDashboardFeature.State(room: room, instanceID: originalID)
    original.dashboard = MockClassOwnerDashboard.figma
    original.sourceViewState = .ready
    var state = ClassCoordinator.State()
    state.routes.push(.detail(.init(room: room)))
    state.routes.push(.ownerDashboard(original))
    let store = TestStore(initialState: state) { ClassCoordinator() } withDependencies: {
      $0.classResultUseCase = generator
      $0.uuid = .incrementing
    }
    store.exhaustivity = .off

    await store.send(.router(.routeAction(id: 2, action: .ownerDashboard(.async(.generateInsight)))))
    await generator.waitForStarts(1)
    await store.send(.router(.routeAction(id: 2, action: .ownerDashboard(.async(.generatePersonal)))))
    await generator.waitForStarts(2)
    guard case let .ownerDashboard(active)? = store.state.routes.last?.screen else {
      Issue.record("기존 대시보드가 없습니다.")
      return
    }
    let insightRequestID = try #require(active.insightRequestID)
    let feedbackRequestID = try #require(active.feedbackRequestID)
    var replacementRoutes = store.state.routes
    replacementRoutes[screenAt: 2] = .ownerDashboard(.init(room: room, instanceID: replacementID))
    await store.send(.router(.updateRoutes(replacementRoutes)))
    await store.finish(timeout: .seconds(1))
    let cancelledIDs = await generator.cancelledRequestIDs
    #expect(Set(cancelledIDs) == [1, 2])

    await store.send(.router(.routeAction(id: 2, action: .ownerDashboard(.inner(.insightResponse(
      instanceID: originalID,
      requestID: insightRequestID,
      roomID: room.id,
      .success(.classInsight("늦은 인사이트")),
      wasUnknown: false
    ))))))
    await store.send(.router(.routeAction(id: 2, action: .ownerDashboard(.inner(.feedbackResponse(
      instanceID: originalID,
      requestID: feedbackRequestID,
      roomID: room.id,
      .success(.personal(.fixture)),
      wasUnknown: false
    ))))))
    guard case let .ownerDashboard(replacement)? = store.state.routes.last?.screen else {
      Issue.record("교체된 대시보드가 없습니다.")
      return
    }
    #expect(replacement.instanceID == replacementID)
    #expect(replacement.generatedInsight == nil)
    #expect(replacement.generatedFeedback == nil)
  }
}

private extension ClassAIPersonalFeedback {
  static let fixture = Self(
    summaryTitle: "생성된 제목",
    summaryDetail: "생성된 분석",
    points: [
      .init(title: "첫 관점", detail: "첫 설명"),
      .init(title: "둘째 관점", detail: "둘째 설명"),
      .init(title: "셋째 관점", detail: "셋째 설명"),
    ],
    nextQuestion: "다음 질문?",
    nextHint: "다음 힌트"
  )
}

private actor SuspendedFeedbackGenerator: ClassResultInterface {
  private enum Request {
    case personal(CheckedContinuation<ClassAIPersonalFeedback, Error>)
    case insight(CheckedContinuation<ClassAIInsight, Error>)

    func resume(with result: ClassAIFeedbackResult) {
      switch (self, result) {
      case let (.personal(continuation), .personal(feedback)):
        continuation.resume(returning: feedback)
      case let (.insight(continuation), .serverInsight(insight)):
        continuation.resume(returning: insight)
      case let (.insight(continuation), .classInsight(text)):
        continuation.resume(returning: ClassAIInsight(text: text))
      case let (.personal(continuation), _):
        continuation.resume(throwing: ClassAIFeedbackError.generationFailed)
      case let (.insight(continuation), _):
        continuation.resume(throwing: ClassAIFeedbackError.generationFailed)
      }
    }

    func cancel() {
      switch self {
      case let .personal(continuation): continuation.resume(throwing: CancellationError())
      case let .insight(continuation): continuation.resume(throwing: CancellationError())
      }
    }
  }

  private var nextRequestID = 0
  private var requests: [Int: Request] = [:]
  private var startedCount = 0
  private var startWaiters: [(Int, CheckedContinuation<Void, Never>)] = []
  private(set) var cancelledRequestIDs: [Int] = []

  func waitForStarts(_ count: Int) async {
    guard startedCount < count else { return }
    await withCheckedContinuation { continuation in
      startWaiters.append((count, continuation))
    }
  }

  func complete(
    requestID: Int,
    result: ClassAIFeedbackResult
  ) {
    requests.removeValue(forKey: requestID)?.resume(with: result)
  }

  func fetch(roomID _: Int) async throws -> ClassResult {
    throw ClassError.network("이 테스트는 결과 조회를 사용하지 않습니다.")
  }

  func fetchPersonal(roomID _: Int) async throws -> ClassAIPersonalFeedback {
    try await suspend { .personal($0) }
  }

  func fetchInsight(roomID _: Int) async throws -> ClassAIInsight {
    try await suspend { .insight($0) }
  }

  func retryInsight(roomID _: Int) async throws {
    throw ClassAIFeedbackError.generationFailed
  }

  private func suspend<T: Sendable>(
    request: @escaping @Sendable (CheckedContinuation<T, Error>) -> Request
  ) async throws -> T {
    nextRequestID += 1
    let requestID = nextRequestID
    return try await withTaskCancellationHandler {
      try await withCheckedThrowingContinuation { continuation in
        requests[requestID] = request(continuation)
        startedCount += 1
        let ready = startWaiters.filter { startedCount >= $0.0 }
        startWaiters.removeAll { startedCount >= $0.0 }
        for (_, waiter) in ready {
          waiter.resume()
        }
      }
    } onCancel: {
      Task { await self.cancel(requestID) }
    }
  }

  private func cancel(_ requestID: Int) {
    guard let request = requests.removeValue(forKey: requestID) else { return }
    cancelledRequestIDs.append(requestID)
    request.cancel()
  }
}
