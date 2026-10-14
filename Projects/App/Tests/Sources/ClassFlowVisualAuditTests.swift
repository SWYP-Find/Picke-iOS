//
//  ClassFlowVisualAuditTests.swift
//  PickeTests
//
//  Created by Picke on 10/11/26.
//

import AudioPlayerServiceInterface
import BattleDomainInterface
import ComposableArchitecture
import ConcurrencyExtras
import DomainAssembly
import FeatureAssembly
import HomeDomainInterface
@testable import Picke
import PickeAnalyticsInterface
import PickeCoreUtility
import SwiftUI
import TCAFlow
import UIKit
import Vision
import XCTest

/// Run explicitly with PICKE_CLASS_VISUAL_AUDIT=1. These images are evidence for
/// manual Figma comparison, not snapshot assertions or proof of design parity.
final class ClassFlowVisualAuditTests: XCTestCase {
  @MainActor
  func testClassCommentReportFlow() async throws {
    guard ProcessInfo.processInfo.environment["PICKE_CLASS_VISUAL_AUDIT"] == "1" else {
      throw XCTSkip("Set PICKE_CLASS_VISUAL_AUDIT=1 to verify mounted report navigation")
    }
    for isAI in [false, true] {
      let original = ClassRoom.mockJoinable
      let battle: ClassBattleSummary = if isAI {
        try XCTUnwrap(ClassSettingFeature.State(
          aiQuestion: ClassAIQuestion.examples[0], filter: .init(), deadline: original.deadline
        ).aiBattle)
      } else {
        original.battle
      }
      let room = ClassRoom(
        id: original.id, name: original.name, joinCode: original.joinCode, battle: battle,
        deadline: original.deadline, memberCount: original.memberCount, role: .member,
        status: original.status, allowsAnonymousOpinion: original.allowsAnonymousOpinion,
        requiresComment: original.requiresComment
      )
      let session = ClassMockChatSession()
      let battleID = await session.register(room: room)
      let repository = MockClassRepository(
        rooms: [room], availableRooms: [], reports: [room.id: MockClassReport.figma]
      )
      var state = ClassCoordinator.State()
      state.routes.push(.detail(.init(room: room)))
      if isAI {
        state.routes.push(.aiVote(.init(room: room, battleID: battleID, instanceID: UUID())))
        state.routes.push(.aiChat(.init(room: room, battleID: battleID, selectedOptionID: 1)))
      }
      state.routes.push(.chat(.init(route: .comment(battleId: battleID))))
      state.chatRoomsByBattleID[battleID] = room
      let store = Store(initialState: state) {
        ClassCoordinator()
          .dependency(\.classUseCase, repository)
          .dependency(\.classMockRepository, repository)
          .dependency(\.classMockChatSession, session)
          .dependency(\.classMockAudioPlayer, ClassMockAudioPlayer())
          .dependency(\.battleUseCase, session)
          .dependency(\.perspectiveUseCase, session)
          .dependency(\.commentUseCase, session)
          .dependency(\.classAIChatUseCase, MockClassAIChatUseCase())
          .dependency(\.classAIFeedbackUseCase, Self.visualAIFeedbackUseCase())
          .dependency(\.analyticsUseCase, .testValue)
          .dependency(\.shareUseCase, .testValue)
      }
      let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
      let window = UIWindow(windowScene: scene)
      let host = UIHostingController(rootView: ClassCoordinatorView(store: store))
      window.rootViewController = host
      window.frame = scene.coordinateSpace.bounds
      window.makeKeyAndVisible()
      defer { window.isHidden = true }
      try await waitForClassAudit("loaded comment") {
        guard case let .chat(chat)? = store.routes.last?.screen,
              case let .comment(comment)? = chat.routes.last?.screen else { return false }
        return !comment.title.isEmpty && !comment.isLoadingStats && !comment.isLoadingComments
      }
      XCTAssertFalse(store.showsTabBar)
      let commentImage = try await saveClassAudit(
        window: window,
        name: isAI ? "report-before-ai" : "report-before-regular"
      )
      let commentText = try recognizedAuditText(
        in: commentImage,
        name: isAI ? "report-before-ai" : "report-before-regular"
      )
      XCTAssertFalse(containsReportHeadings(commentText), "Comment must not satisfy the report pixel check")
      store.send(.view(.chatReportTapped(battleID: battleID)))
      do {
        try await waitForClassAudit("loaded report after route replacement") {
          guard case let .report(report)? = store.routes.last?.screen else { return false }
          if case .ready = report.feedbackViewState {
            return report.sourceViewState == .ready
          }
          return false
        }
      } catch {
        let routeDescription = if case let .report(report)? = store.routes.last?.screen {
          "report source=\(report.sourceViewState), request=\(String(describing: report.requestID))"
        } else {
          "last route is not report"
        }
        let attachment = XCTAttachment(string: "isAI=\(isAI); \(routeDescription)")
        attachment.name = "report-flow-state"
        attachment.lifetime = .keepAlways
        add(attachment)
        try await saveClassAudit(window: window, name: isAI ? "report-flow-failed-ai" : "report-flow-failed-regular")
        throw error
      }
      XCTAssertEqual(store.routes.count, 3)
      XCTAssertFalse(store.showsTabBar)
      let reportName = isAI ? "comment-to-report-ai" : "comment-to-report-regular"
      let reportImage = try await saveClassAudit(window: window, name: reportName)
      let reportText = try recognizedAuditText(in: reportImage, name: reportName)
      XCTAssertTrue(containsReportHeadings(reportText), "Report headings missing from rendered pixels: \(reportText)")
      store.send(.router(.routeAction(id: 2, action: .report(.view(.backTapped)))))
      try await waitForClassAudit("original detail after report back") {
        guard case let .detail(detail)? = store.routes.last?.screen else { return false }
        return store.routes.count == 2 && detail.room.id == room.id && store.showsTabBar
      }
      let detailName = isAI ? "report-back-detail-ai" : "report-back-detail-regular"
      let detailImage = try await saveClassAudit(window: window, name: detailName)
      let detailText = try recognizedAuditText(in: detailImage, name: detailName)
      XCTAssertTrue(detailText.contains("클래스상세"), "Detail title missing from rendered pixels: \(detailText)")
      XCTAssertTrue(detailText.contains("이번클래스배틀"), "Detail battle section missing: \(detailText)")
      XCTAssertFalse(containsReportHeadings(detailText), "Report must no longer be displayed after back")
    }
  }

  @MainActor
  func testClassReportLayoutFooters() async throws {
    guard ProcessInfo.processInfo.environment["PICKE_CLASS_VISUAL_AUDIT"] == "1" else {
      throw XCTSkip("Set PICKE_CLASS_VISUAL_AUDIT=1 to verify report layout footers")
    }
    let directory = try FileManager.default.url(
      for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true
    ).appendingPathComponent("ClassVisualAudit", isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

    for layout in [ClassReportLayout.summary, .tabbed] {
      let fixture = MockClassReport.figma
      var state = ClassReportFeature.State(room: .mockClosedSociety, instanceID: UUID())
      state.report = ClassReport(
        texts: fixture.texts,
        myOpinions: fixture.myOpinions,
        initialVoteLeading: fixture.initialVoteLeading,
        finalVoteLeading: fixture.finalVoteLeading,
        layout: layout
      )
      state.sourceViewState = .ready
      state.feedback = Self.visualPersonalFeedback
      state.selectedTab = .summary
      let store = Store(initialState: state) { ClassReportFeature() }
      let (_, bottomImage) = try await capture(
        AnyView(ClassReportView(store: store)),
        ready: nil,
        includeScrollBottom: true,
        viewport: CGSize(width: 402, height: 640)
      )
      let image = try XCTUnwrap(bottomImage)
      let name = layout == .summary ? "report-summary-footer" : "report-tabbed-footer"
      try XCTUnwrap(image.pngData()).write(to: directory.appendingPathComponent(name + ".png"))
      let attachment = XCTAttachment(image: image)
      attachment.name = name
      attachment.lifetime = .keepAlways
      add(attachment)
      let text = try recognizedAuditText(in: image, name: name)

      if layout == .summary {
        XCTAssertTrue(text.contains("다음생각한걸음"), "In-card next step missing: \(text)")
        XCTAssertTrue(text.contains("내가남긴의견"), "Summary bottom was not captured: \(text)")
        XCTAssertFalse(text.contains("다음생각해보기"), "Duplicate footer remains: \(text)")
      } else {
        XCTAssertTrue(text.contains("다음생각해보기"), "Legacy next step missing: \(text)")
        XCTAssertTrue(text.contains("참여기록"), "Tabbed page links missing: \(text)")
        XCTAssertTrue(text.contains("클래스결과"), "Tabbed page links missing: \(text)")
        XCTAssertTrue(text.contains("피드백"), "Tabbed page links missing: \(text)")
      }
    }
  }

  @MainActor
  func testClassAIFeedbackStatusFrames() async throws {
    guard ProcessInfo.processInfo.environment["PICKE_CLASS_VISUAL_AUDIT"] == "1" else {
      throw XCTSkip("Set PICKE_CLASS_VISUAL_AUDIT=1 to capture generated-feedback statuses")
    }
    let directory = try FileManager.default.url(
      for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true
    ).appendingPathComponent("ClassVisualAudit", isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

    func saveStatus(_ name: String, view: AnyView, unavailableText: String?) async throws {
      let (image, _) = try await capture(view, ready: nil, includeScrollBottom: false)
      try XCTUnwrap(image.pngData()).write(to: directory.appendingPathComponent(name + ".png"))
      let attachment = XCTAttachment(image: image)
      attachment.name = name + " (seeded AI status; no model call)"
      attachment.lifetime = .keepAlways
      add(attachment)
      if let unavailableText {
        let text = try recognizedAuditText(in: image, name: name)
        XCTAssertTrue(text.contains(unavailableText), "Expected AI unavailable message in pixels: \(text)")
      }
    }

    var member = ClassReportFeature.State(room: .mockClosedSociety, instanceID: UUID())
    member.report = MockClassReport.figma
    member.sourceViewState = .ready
    member.isGeneratingFeedback = true
    XCTAssertEqual(member.feedbackViewState, .loading)
    try await saveStatus(
      "member-feedback-generating",
      view: AnyView(ClassReportView(store: Store(initialState: member) {
        ClassReportFeature()
      })),
      unavailableText: nil
    )
    member.isGeneratingFeedback = false
    member.feedbackError = .deviceNotEligible
    XCTAssertEqual(member.feedbackViewState, .unavailable)
    try await saveStatus(
      "member-feedback-unavailable",
      view: AnyView(ClassReportView(store: Store(initialState: member) {
        ClassReportFeature()
      })),
      unavailableText: "피드백을사용할수없어요"
    )

    var owner = ClassOwnerDashboardFeature.State(room: ClassRoom.mocks[0], instanceID: UUID())
    let dashboard = MockClassOwnerDashboard.figma
    owner.dashboard = dashboard
    owner.report = dashboard.report
    owner.members = dashboard.members
    owner.opinions = dashboard.opinions
    owner.metrics = dashboard.metrics
    owner.sourceViewState = .ready
    owner.isGeneratingInsight = true
    XCTAssertEqual(owner.insightViewState, .loading)
    try await saveStatus(
      "owner-insight-generating",
      view: AnyView(ClassOwnerDashboardView(store: Store(initialState: owner) {
        ClassOwnerDashboardFeature()
      })),
      unavailableText: nil
    )
    owner.isGeneratingInsight = false
    owner.insightError = .deviceNotEligible
    XCTAssertEqual(owner.insightViewState, .unavailable)
    try await saveStatus(
      "owner-insight-unavailable",
      view: AnyView(ClassOwnerDashboardView(store: Store(initialState: owner) {
        ClassOwnerDashboardFeature()
      })),
      unavailableText: "인사이트를사용할수없어요"
    )

    owner.selectedTab = .report
    owner.isGeneratingFeedback = true
    XCTAssertEqual(owner.feedbackViewState, .loading)
    try await saveStatus(
      "owner-feedback-generating",
      view: AnyView(ClassOwnerDashboardView(store: Store(initialState: owner) {
        ClassOwnerDashboardFeature()
      })),
      unavailableText: nil
    )
    owner.isGeneratingFeedback = false
    owner.feedbackError = .deviceNotEligible
    XCTAssertEqual(owner.feedbackViewState, .unavailable)
    try await saveStatus(
      "owner-feedback-unavailable",
      view: AnyView(ClassOwnerDashboardView(store: Store(initialState: owner) {
        ClassOwnerDashboardFeature()
      })),
      unavailableText: "피드백을사용할수없어요"
    )

    let openRoom = ClassRoom.mocks[0]
    let closedRoom = ClassRoom(
      id: openRoom.id,
      name: openRoom.name,
      joinCode: openRoom.joinCode,
      battle: openRoom.battle,
      deadline: openRoom.deadline,
      memberCount: openRoom.memberCount,
      role: openRoom.role,
      status: .closed,
      allowsAnonymousOpinion: openRoom.allowsAnonymousOpinion,
      requiresComment: openRoom.requiresComment,
      ownerParticipates: openRoom.ownerParticipates
    )
    var closedOwner = ClassOwnerDashboardFeature.State(room: closedRoom, instanceID: UUID())
    closedOwner.selectedTab = .home
    closedOwner.dashboard = dashboard
    closedOwner.report = dashboard.report
    closedOwner.members = dashboard.members
    closedOwner.opinions = dashboard.opinions
    closedOwner.metrics = dashboard.metrics
    closedOwner.sourceViewState = .ready
    let multilineInsight = """
    서로 다른 의견을 비교하며 근거를 살펴봤어요.
    대화를 통해 다양한 관점을 이해했어요.
    다음 토론에서도 자신의 생각을 구체적으로 표현해 보세요.
    """
    closedOwner.generatedInsight = multilineInsight
    XCTAssertEqual(closedOwner.room.status, .closed)
    XCTAssertEqual(closedOwner.insightViewState, .ready(multilineInsight))
    try await saveStatus(
      "owner-closed-insight-multiline",
      view: AnyView(ClassOwnerDashboardView(store: Store(initialState: closedOwner) {
        ClassOwnerDashboardFeature()
      })),
      unavailableText: "다음토론에서도자신의생각을구체적으로표현해보세요"
    )
    let closedImage = try XCTUnwrap(UIImage(contentsOfFile: directory
      .appendingPathComponent("owner-closed-insight-multiline.png").path))
    let closedText = try recognizedAuditText(in: closedImage, name: "owner-closed-insight-multiline")
    XCTAssertTrue(closedText.contains("종료"), "Closed badge missing from pixels: \(closedText)")

    var reportOwner = ClassOwnerDashboardFeature.State(room: closedRoom, instanceID: UUID())
    reportOwner.selectedTab = .report
    reportOwner.sourceViewState = .ready
    reportOwner.report = dashboard.report
    reportOwner.generatedFeedback = Self.visualPersonalFeedback
    XCTAssertEqual(reportOwner.feedbackViewState, .ready(Self.visualPersonalFeedback))
    let (_, reportBottom) = try await capture(
      AnyView(ClassOwnerDashboardView(store: Store(initialState: reportOwner) {
        ClassOwnerDashboardFeature()
      })),
      ready: nil,
      includeScrollBottom: true,
      viewport: CGSize(width: 402, height: 640)
    )
    let reportImage = try XCTUnwrap(reportBottom)
    let reportName = "owner-report-final-bottom"
    try XCTUnwrap(reportImage.pngData()).write(to: directory.appendingPathComponent(reportName + ".png"))
    let reportAttachment = XCTAttachment(image: reportImage)
    reportAttachment.name = reportName + " (seeded AI feedback; no model call)"
    reportAttachment.lifetime = .keepAlways
    add(reportAttachment)
    let reportText = try recognizedAuditText(in: reportImage, name: reportName)
    XCTAssertTrue(reportText.contains("다음생각한걸음"), "In-card next step missing: \(reportText)")
    XCTAssertTrue(reportText.contains("내가남긴의견\(reportOwner.myOpinionCount)개보기"), "Owner footer missing: \(reportText)")
    XCTAssertFalse(reportText.contains("다음생각해보기"), "Duplicate external next-step heading remains: \(reportText)")
  }

  @MainActor
  func testClassMemberAndVoteLoadStates() async throws {
    guard ProcessInfo.processInfo.environment["PICKE_CLASS_VISUAL_AUDIT"] == "1" else {
      throw XCTSkip("Set PICKE_CLASS_VISUAL_AUDIT=1 to capture member and AI vote states")
    }
    let directory = try FileManager.default.url(
      for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true
    ).appendingPathComponent("ClassVisualAudit", isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

    func saveState(
      _ name: String,
      view: AnyView,
      expectedText: String?,
      additionalExpectedText: [String] = [],
      excludedText: [String] = [],
      ready: (@MainActor () -> Bool)? = nil
    ) async throws {
      let (image, _) = try await capture(view, ready: ready, includeScrollBottom: false,
                                         viewport: CGSize(width: 402, height: 874))
      try XCTUnwrap(image.pngData()).write(to: directory.appendingPathComponent(name + ".png"))
      let attachment = XCTAttachment(image: image)
      attachment.name = name + " (seeded load state)"
      attachment.lifetime = .keepAlways
      add(attachment)
      if expectedText != nil || !additionalExpectedText.isEmpty || !excludedText.isEmpty {
        let text = try recognizedAuditText(in: image, name: name)
        if let expectedText {
          XCTAssertTrue(text.contains(expectedText), "Expected load-state message in pixels: \(text)")
        }
        for expected in additionalExpectedText {
          XCTAssertTrue(text.contains(expected), "Expected vote control in load-state pixels: \(text)")
        }
        for excluded in excludedText {
          XCTAssertFalse(text.contains(excluded), "Unexpected vote option in load-state pixels: \(text)")
        }
      }
    }

    let room = ClassRoom.mockJoinable
    var member = ClassMemberFeature.State(room: room, instanceID: UUID())
    member.viewState = .loading
    XCTAssertEqual(member.viewState, .loading)
    try await saveState("member-loading", view: AnyView(ClassMemberView(store: Store(initialState: member) {
      ClassMemberFeature()
    })), expectedText: nil)
    member.loadErrorMessage = "멤버 정보를 불러올 수 없어요."
    member.viewState = .error
    XCTAssertEqual(member.viewState, .error)
    try await saveState("member-error", view: AnyView(ClassMemberView(store: Store(initialState: member) {
      ClassMemberFeature()
    })), expectedText: "멤버목록을불러올수없어요")
    member.loadErrorMessage = nil
    member.viewState = .empty
    XCTAssertEqual(member.viewState, .empty)
    try await saveState("member-empty", view: AnyView(ClassMemberView(store: Store(initialState: member) {
      ClassMemberFeature()
    })), expectedText: "아직참여한멤버가없어요")

    let voteRoom = room
    let battleID = 1001
    let requestID = UUID()
    let suspended = AsyncStream<Never>.makeStream()
    let loadingUseCase = VoteCaptureBattleUseCase { _ in
      for await _ in suspended.stream {}
      throw CancellationError()
    }
    let loadingStore = Store(initialState: ClassAIVoteFeature.State(
      room: voteRoom,
      battleID: battleID,
      instanceID: UUID()
    )) {
      ClassAIVoteFeature()
        .dependency(\.battleUseCase, loadingUseCase)
        .dependency(\.uuid, .constant(requestID))
    }
    defer {
      loadingStore.send(.view(.backTapped))
      suspended.continuation.finish()
    }
    XCTAssertEqual(loadingStore.viewState, .loading)
    try await saveState(
      "ai-vote-loading",
      view: AnyView(ClassAIVoteView(store: loadingStore)),
      expectedText: "투표하기",
      excludedText: [voteRoom.battle.optionATitle, voteRoom.battle.optionBTitle].map {
        $0.filter { !$0.isWhitespace }
      },
      ready: {
        loadingStore.viewState == .loading && loadingStore.loadRequestID == requestID
          && !loadingStore.canSubmit
          && loadingUseCase.fetchCalls.value.count == 1
          && loadingUseCase.fetchCalls.value.battleID == battleID
      }
    )
    XCTAssertEqual(loadingStore.viewState, .loading)
    XCTAssertEqual(loadingStore.loadRequestID, requestID)
    XCTAssertEqual(loadingUseCase.fetchCalls.value.count, 1)
    XCTAssertEqual(loadingUseCase.fetchCalls.value.battleID, battleID)
    XCTAssertFalse(loadingStore.canSubmit)

    let errorUseCase = VoteCaptureBattleUseCase { _ in
      throw NSError(domain: "VoteCapture", code: 1)
    }
    let errorStore = Store(initialState: ClassAIVoteFeature.State(
      room: voteRoom,
      battleID: battleID,
      instanceID: UUID()
    )) {
      ClassAIVoteFeature()
        .dependency(\.battleUseCase, errorUseCase)
        .dependency(\.uuid, .constant(requestID))
    }
    XCTAssertEqual(errorStore.viewState, .loading)
    try await saveState(
      "ai-vote-error",
      view: AnyView(ClassAIVoteView(store: errorStore)),
      expectedText: "투표상태를불러오지못했어요",
      additionalExpectedText: ["다시시도"],
      ready: {
        errorStore.viewState == .error && errorStore.loadRequestID == nil
          && !errorStore.canSubmit
          && errorStore.errorMessage == "투표 상태를 불러오지 못했어요. 다시 시도해 주세요."
          && errorUseCase.fetchCalls.value.count == 1
          && errorUseCase.fetchCalls.value.battleID == battleID
      }
    )
    XCTAssertEqual(errorStore.viewState, .error)
    XCTAssertNil(errorStore.loadRequestID)
    XCTAssertEqual(errorUseCase.fetchCalls.value.count, 1)
    XCTAssertEqual(errorUseCase.fetchCalls.value.battleID, battleID)
    XCTAssertFalse(errorStore.canSubmit)
  }

  @MainActor
  func testClassCommentLongEditPresentation() async throws {
    guard ProcessInfo.processInfo.environment["PICKE_CLASS_VISUAL_AUDIT"] == "1" else {
      throw XCTSkip("Set PICKE_CLASS_VISUAL_AUDIT=1 to verify comment editing")
    }
    let room = ClassRoom.mockJoinable
    let session = ClassMockChatSession()
    let battleID = await session.register(room: room)
    let longText = (1 ... 5).map { "\($0)번째 의견입니다. 서로 다른 입장의 근거를 함께 살펴보고 싶어요." }.joined(separator: "\n")
    let battleAPI: any BattleInterface = session
    _ = try await battleAPI.submitPreVote(battleId: battleID, optionId: 1)
    _ = try await battleAPI.submitPostVote(battleId: battleID, optionId: 1)
    _ = try await battleAPI.createPerspective(battleId: battleID, content: longText, optionId: 1)
    let store = Store(initialState: CommentFeature.State(battleId: battleID)) {
      CommentFeature()
        .dependency(\.battleUseCase, session)
        .dependency(\.perspectiveUseCase, session)
        .dependency(\.commentUseCase, session)
        .dependency(\.analyticsUseCase, .testValue)
    }
    let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
    let window = UIWindow(windowScene: scene)
    let host = UIHostingController(rootView: ClassCommentView(store: store, onOpenReport: { _ in }))
    window.rootViewController = host
    window.frame = scene.coordinateSpace.bounds
    window.makeKeyAndVisible()
    defer { window.isHidden = true }
    try await waitForClassAudit("my loaded comment") {
      !store.isLoadingComments && store.comments.contains { $0.isMine }
    }
    store.send(.binding(.set(\.commentText, "작성 중인 의견")))
    XCTAssertTrue(store.isSendEnabled)
    try await saveClassAudit(window: window, name: "comment-draft")
    let comment = try XCTUnwrap(store.comments.first { $0.isMine })
    store.send(.view(.commentMenu(id: comment.id, action: .edit)))
    XCTAssertEqual(store.commentText, longText)
    XCTAssertNotNil(store.editingPerspectiveId)
    XCTAssertTrue(store.isSendEnabled)
    try await saveClassAudit(window: window, name: "comment-edit-five-lines")
    store.send(.view(.composeDismissed))
    XCTAssertEqual(store.commentText, "")
    XCTAssertNil(store.editingPerspectiveId)
    XCTAssertFalse(store.isSendEnabled)
    try await saveClassAudit(window: window, name: "comment-edit-cancelled")
  }

  @MainActor
  private func waitForClassAudit(_ description: String, until predicate: () -> Bool) async throws {
    for _ in 0 ..< 100 {
      if predicate() {
        return
      }
      try await Task.sleep(for: .milliseconds(50))
    }
    XCTFail("Class audit did not reach: \(description)")
    throw CaptureError.contentNotReady
  }

  private func containsReportHeadings(_ text: String) -> Bool {
    // Vision can read the capital I in AI as a lowercase l.
    text.contains("내투표결과")
      && (text.contains("AI피드백") || text.contains("Al피드백"))
  }

  @MainActor
  private func recognizedAuditText(
    in image: UIImage,
    name: String,
    usesLanguageCorrection: Bool = true,
    regionOfInterest: CGRect? = nil
  ) throws -> String {
    let request = VNRecognizeTextRequest()
    request.recognitionLevel = .accurate
    let languages = try request.supportedRecognitionLanguages()
    XCTAssertTrue(languages.contains("ko-KR"), "Korean OCR is required for this visual audit")
    request.recognitionLanguages = ["ko-KR", "en-US"]
    request.usesLanguageCorrection = usesLanguageCorrection
    if let regionOfInterest {
      request.regionOfInterest = regionOfInterest
    }
    let cgImage = try XCTUnwrap(image.cgImage)
    try VNImageRequestHandler(cgImage: cgImage).perform([request])
    let rawText = (request.results ?? []).compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
    let attachment = XCTAttachment(string: rawText)
    attachment.name = name + "-recognized-text"
    attachment.lifetime = .keepAlways
    add(attachment)
    let directory = try FileManager.default.url(
      for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true
    ).appendingPathComponent("ClassVisualAudit", isDirectory: true)
    try rawText.write(to: directory.appendingPathComponent(name + ".txt"), atomically: true, encoding: .utf8)
    return rawText.filter { !$0.isWhitespace }
  }

  @MainActor
  @discardableResult
  private func saveClassAudit(window: UIWindow, name: String) async throws -> UIImage {
    try await Task.sleep(for: .milliseconds(500))
    window.layoutIfNeeded()
    CATransaction.flush()
    let image = UIGraphicsImageRenderer(bounds: window.bounds).image { _ in
      window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
    }
    let directory = try FileManager.default.url(
      for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true
    ).appendingPathComponent("ClassVisualAudit", isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    try XCTUnwrap(image.pngData()).write(to: directory.appendingPathComponent(name + ".png"))
    let attachment = XCTAttachment(image: image)
    attachment.name = name
    attachment.lifetime = .keepAlways
    add(attachment)
    return image
  }

  @MainActor
  func testClassFinalVoteSharePresentation() async throws {
    guard ProcessInfo.processInfo.environment["PICKE_CLASS_VISUAL_AUDIT"] == "1" else {
      throw XCTSkip("Set PICKE_CLASS_VISUAL_AUDIT=1 to verify Class share presentation")
    }
    let room = ClassRoom.mockJoinable
    let session = ClassMockChatSession()
    let battleID = await session.register(room: room)
    let store = Store(initialState: PreVoteFeature.State(battleId: battleID, voteMode: .post)) {
      PreVoteFeature()
        .dependency(\.battleUseCase, session)
        .dependency(\.perspectiveUseCase, session)
        .dependency(\.shareUseCase, .testValue)
        .dependency(\.analyticsUseCase, .testValue)
    }
    let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
    let window = UIWindow(windowScene: scene)
    let host = UIHostingController(rootView: ClassVoteView(store: store, room: room))
    window.rootViewController = host
    window.frame = scene.coordinateSpace.bounds
    window.makeKeyAndVisible()
    defer { window.isHidden = true }

    func waitFor(_ description: String, until predicate: () -> Bool) async throws {
      for _ in 0 ..< 100 {
        if predicate() {
          return
        }
        try await Task.sleep(for: .milliseconds(50))
      }
      XCTFail("Class share did not reach: \(description)")
      throw CaptureError.contentNotReady
    }
    func activityController(in controller: UIViewController) -> UIActivityViewController? {
      if let activity = controller as? UIActivityViewController {
        return activity
      }
      if let presented = controller.presentedViewController,
         let activity = activityController(in: presented)
      {
        return activity
      }
      return controller.children.lazy.compactMap { activityController(in: $0) }.first
    }

    try await waitFor("loaded final vote") {
      store.battle != nil && !store.detailLoadFailed && store.viewState == .loaded
    }
    store.send(.view(.shareTapped))
    try await waitFor("share sheet") {
      store.shareSnapshotRequest == nil && store.shareItem != nil
        && activityController(in: host)?.view.window != nil
    }
    let shareID = try XCTUnwrap(store.shareItem?.id)
    // A nil-reset observation must not create a second item and re-present the sheet.
    for _ in 0 ..< 10 {
      try await Task.sleep(for: .milliseconds(50))
      XCTAssertEqual(store.shareItem?.id, shareID)
    }
    let shareController = try XCTUnwrap(activityController(in: host))
    let shareWindow = try XCTUnwrap(shareController.view.window)
    shareWindow.layoutIfNeeded()
    let image = UIGraphicsImageRenderer(bounds: shareWindow.bounds).image { _ in
      shareWindow.drawHierarchy(in: shareWindow.bounds, afterScreenUpdates: true)
    }
    let directory = try FileManager.default.url(
      for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true
    ).appendingPathComponent("ClassVisualAudit", isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    try XCTUnwrap(image.pngData()).write(to: directory.appendingPathComponent("final-vote-share-sheet.png"))
    let attachment = XCTAttachment(image: image)
    attachment.name = "final-vote-share-sheet"
    attachment.lifetime = .keepAlways
    add(attachment)

    store.send(.binding(.set(\.shareItem, nil)))
    try await waitFor("dismissed share sheet") {
      store.shareItem == nil && host.presentedViewController == nil
    }
    try await Task.sleep(for: .milliseconds(500))
    XCTAssertNil(store.shareItem)
    XCTAssertNil(store.shareSnapshotRequest)
    XCTAssertNil(host.presentedViewController)
    XCTAssertEqual(store.voteMode, .post)
    XCTAssertNotNil(store.battle)
  }

  @MainActor
  func testPresentClassTabForInteractiveAudit() async throws {
    guard ProcessInfo.processInfo.environment["PICKE_CLASS_INTERACTIVE_AUDIT"] == "1" else {
      throw XCTSkip("Set PICKE_CLASS_INTERACTIVE_AUDIT=1 for a manual Class tab session")
    }
    let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
    let window = UIWindow(windowScene: scene)
    let memberAudit = ProcessInfo.processInfo.environment["PICKE_CLASS_MEMBER_AUDIT"] == "1"
    let repository = memberAudit ? MockClassRepository(rooms: memberRooms, availableRooms: []) : MockClassRepository()
    let session = ClassMockChatSession()
    var state = MainTabCoordinator.State(selectedTab: MainTabCoordinator.Tab.classroom.rawValue)
    if memberAudit {
      state.classState.routes.push(.myClasses(.init()))
    }
    let store = Store(initialState: state) {
      MainTabCoordinator()
        .dependency(\.classUseCase, repository)
        .dependency(\.classMockRepository, repository)
        .dependency(\.classMockChatSession, session)
        .dependency(\.classMockAudioPlayer, ClassMockAudioPlayer())
    }
    window.rootViewController = UIHostingController(rootView: MainTabView(store: store))
    window.frame = scene.coordinateSpace.bounds
    window.makeKeyAndVisible()
    defer { window.isHidden = true }
    try await Task.sleep(for: .seconds(180))
  }

  @MainActor
  func testCaptureMemberManagementFlow() async throws {
    guard ProcessInfo.processInfo.environment["PICKE_CLASS_VISUAL_AUDIT"] == "1" else {
      throw XCTSkip("Set PICKE_CLASS_VISUAL_AUDIT=1 to capture member management")
    }
    let rooms = memberRooms
    let repository = MockClassRepository(rooms: rooms, availableRooms: [])
    var state = MainTabCoordinator.State(selectedTab: MainTabCoordinator.Tab.classroom.rawValue)
    state.classState.routes.push(.myClasses(.init()))
    let store = withDependencies {
      $0.context = .test
      $0.uuid = .incrementing
    } operation: {
      Store(initialState: state) {
        MainTabCoordinator()
          .dependency(\.classUseCase, repository)
          .dependency(\.classMockRepository, repository)
          .dependency(\.classMockChatSession, ClassMockChatSession())
          .dependency(\.classMockAudioPlayer, ClassMockAudioPlayer())
      }
    }
    let routeID = state.classState.routes.count - 1
    func send(_ action: MyClassFeature.Action) {
      // Presentation effects live until dismissal; wait for the expected state below.
      store.send(.classroom(.router(.routeAction(id: routeID, action: .myClasses(action)))))
    }
    func waitFor(_ description: String, until predicate: (MyClassFeature.State) -> Bool) async throws {
      for _ in 0 ..< 100 {
        if case let .myClasses(list)? = store.classState.routes.last?.screen, predicate(list) {
          return
        }
        try await Task.sleep(for: .milliseconds(50))
      }
      XCTFail("Member management did not reach: \(description)")
      throw CaptureError.contentNotReady
    }
    let directory = try FileManager.default.url(
      for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true
    ).appendingPathComponent("ClassMemberVisualAudit", isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
    let window = UIWindow(windowScene: scene)
    let host = UIHostingController(rootView: MainTabView(store: store))
    window.rootViewController = host
    window.frame = scene.coordinateSpace.bounds
    window.makeKeyAndVisible()
    defer { window.isHidden = true }
    func save(_ name: String) async throws {
      try await Task.sleep(for: .milliseconds(400))
      host.view.layoutIfNeeded()
      CATransaction.flush()
      let image = UIGraphicsImageRenderer(bounds: window.bounds).image { _ in
        window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
      }
      try XCTUnwrap(image.pngData()).write(to: directory.appendingPathComponent(name + ".png"))
      let attachment = XCTAttachment(image: image)
      attachment.name = name
      attachment.lifetime = .keepAlways
      add(attachment)
    }
    send(.view(.onAppear))
    try await waitFor("loaded member list") { !$0.isLoading && $0.rooms.map(\.id) == rooms.map(\.id) }
    try await save("01-member-list")
    send(.view(.managementTapped(rooms[0].id)))
    try await waitFor("management sheet") { $0.modal != nil && $0.selectedRoomID == rooms[0].id }
    XCTAssertFalse(store.classState.showsTabBar)
    try await save("02-member-management")
    send(.view(.leaveTapped))
    try await waitFor("leave confirmation") { $0.modal == nil && $0.customAlert != nil }
    XCTAssertFalse(store.classState.showsTabBar)
    try await save("03-member-leave-confirm")
    send(.customAlert(.presented(.cancelTapped)))
    try await waitFor("cancelled leave") { $0.customAlert == nil && $0.pendingConfirmation == nil }
    XCTAssertTrue(store.classState.showsTabBar)
    let roomsAfterCancel = try await repository.fetchMyClasses()
    XCTAssertEqual(roomsAfterCancel.count, 3)
    send(.view(.managementTapped(rooms[0].id)))
    send(.view(.leaveTapped))
    send(.customAlert(.presented(.confirmTapped)))
    try await waitFor("completed leave cleanup") {
      !$0.isLeaving && $0.rooms.map(\.id) == rooms.dropFirst().map(\.id)
    }
    XCTAssertTrue(store.classState.showsTabBar)
    let remaining = try await repository.fetchMyClasses()
    XCTAssertEqual(remaining.map(\.id), rooms.dropFirst().map(\.id))
    try await save("04-member-left")
  }

  private var memberRooms: [ClassRoom] {
    ClassRoom.mocks.map { room in
      ClassRoom(
        id: room.id, name: room.name, joinCode: room.joinCode, battle: room.battle,
        deadline: Date(timeIntervalSince1970: 1_790_154_000),
        memberCount: room.memberCount, role: .member, status: room.status,
        allowsAnonymousOpinion: room.allowsAnonymousOpinion, requiresComment: room.requiresComment
      )
    }
  }

  @MainActor
  func testCaptureEmptyClassComments() async throws {
    guard ProcessInfo.processInfo.environment["PICKE_CLASS_VISUAL_AUDIT"] == "1" else {
      throw XCTSkip("Set PICKE_CLASS_VISUAL_AUDIT=1 to capture empty comments")
    }
    let room = ClassRoom.mockJoinable
    let session = ClassMockChatSession()
    let battleID = await session.register(room: room)
    let store = withDependencies {
      $0.context = .test
    } operation: {
      Store(initialState: ChatCoordinator.State(route: .comment(battleId: battleID))) {
        ChatCoordinator()
          .dependency(\.battleUseCase, session)
          .dependency(\.perspectiveUseCase, session)
          .dependency(\.commentUseCase, session)
          .dependency(\.analyticsUseCase, .testValue)
      }
    }
    let (image, _) = try await capture(
      AnyView(ClassChatCoordinatorView(store: store, roomsByBattleID: [battleID: room], onOpenReport: { _ in })),
      ready: {
        guard case let .comment(value)? = store.routes.last?.screen else { return false }
        return !value.title.isEmpty && !value.isLoadingComments && !value.isLoadingStats
      },
      includeScrollBottom: false
    )
    guard case let .comment(value)? = store.routes.last?.screen else {
      return XCTFail("Expected the Class comment route")
    }
    XCTAssertTrue(value.comments.isEmpty)
    let directory = try FileManager.default.url(
      for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true
    ).appendingPathComponent("ClassVisualAudit", isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    try XCTUnwrap(image.pngData()).write(to: directory.appendingPathComponent("15-comments-empty.png"))
    let attachment = XCTAttachment(image: image)
    attachment.name = "15-comments-empty"
    attachment.lifetime = .keepAlways
    add(attachment)
  }

  @MainActor
  func testCaptureClassJoinOverlays() async throws {
    guard ProcessInfo.processInfo.environment["PICKE_CLASS_VISUAL_AUDIT"] == "1" else {
      throw XCTSkip("Set PICKE_CLASS_VISUAL_AUDIT=1 to capture Class join push screens")
    }
    let room = ClassRoom.mockJoinable
    let repository = MockClassRepository(rooms: [], availableRooms: [room])
    let directory = try FileManager.default.url(
      for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true
    ).appendingPathComponent("ClassVisualAudit", isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

    func save(
      _ name: String,
      view: AnyView,
      ready: @escaping @MainActor () -> Bool,
      viewport: CGSize? = nil,
      focusTextField: Bool = false
    ) async throws {
      let (image, _) = try await capture(
        view,
        ready: ready,
        includeScrollBottom: false,
        viewport: viewport,
        focusTextField: focusTextField
      )
      try XCTUnwrap(image.pngData()).write(to: directory.appendingPathComponent(name + ".png"))
      let attachment = XCTAttachment(image: image)
      attachment.name = name
      attachment.lifetime = .keepAlways
      add(attachment)
    }

    func joinStore() -> StoreOf<ClassCoordinator> {
      let store = withDependencies {
        $0.uuid = .incrementing
      } operation: {
        Store(initialState: ClassCoordinator.State()) {
          ClassCoordinator().dependency(\.classUseCase, repository)
        }
      }
      store.send(.router(.routeAction(id: 0, action: .intro(.view(.joinTapped)))))
      return store
    }

    let valid = joinStore()
    valid.send(.router(.routeAction(id: 1, action: .join(.binding(.set(\.joinCode, room.joinCode))))))
    try await save(
      "join-valid-code-push",
      view: AnyView(ClassCoordinatorView(store: valid)),
      ready: {
        guard case let .join(code)? = valid.routes.last?.screen else { return false }
        return valid.routes.count == 2 && code.mode == .code && code.canFindClass
      },
      viewport: CGSize(width: 402, height: 874)
    )
    valid.send(.router(.routeAction(id: 1, action: .join(.view(.findTapped)))))
    try await save(
      "join-valid-name-push",
      view: AnyView(ClassCoordinatorView(store: valid)),
      ready: {
        guard case let .join(name)? = valid.routes.last?.screen else { return false }
        return valid.routes.count == 3 && name.mode == .nickname && name.preview?.id == room.id
      },
      viewport: CGSize(width: 402, height: 874)
    )

    let invalid = joinStore()
    invalid.send(.router(.routeAction(id: 1, action: .join(.binding(.set(\.joinCode, "BAD123"))))))
    invalid.send(.router(.routeAction(id: 1, action: .join(.view(.findTapped)))))
    try await save(
      "join-invalid-code-push",
      view: AnyView(ClassCoordinatorView(store: invalid)),
      ready: {
        guard case let .join(code)? = invalid.routes.last?.screen else { return false }
        return invalid.routes.count == 2 && code.mode == .code
          && code.errorMessage == ClassError.invalidCode.message && !code.isLoading
      },
      viewport: CGSize(width: 402, height: 874)
    )

    let duplicate = joinStore()
    duplicate.send(.router(.routeAction(id: 1, action: .join(.binding(.set(\.joinCode, room.joinCode))))))
    duplicate.send(.router(.routeAction(id: 1, action: .join(.view(.findTapped)))))
    try await waitForClassAudit("nickname push") {
      guard case let .join(name)? = duplicate.routes.last?.screen else { return false }
      return duplicate.routes.count == 3 && name.mode == .nickname
    }
    duplicate.send(.router(.routeAction(id: 2, action: .join(.binding(.set(\.nickname, "운영자"))))))
    duplicate.send(.router(.routeAction(id: 2, action: .join(.view(.joinTapped)))))
    try await save(
      "join-duplicate-name-push",
      view: AnyView(ClassCoordinatorView(store: duplicate)),
      ready: {
        guard case let .join(name)? = duplicate.routes.last?.screen else { return false }
        return name.nicknameErrorMessage == ClassError.duplicateName.message && !name.isLoading
      },
      viewport: CGSize(width: 402, height: 874)
    )
    duplicate.send(.router(.routeAction(id: 2, action: .join(.binding(.set(\.nickname, "1234567890123"))))))
    try await save(
      "join-name-overlength-push",
      view: AnyView(ClassCoordinatorView(store: duplicate)),
      ready: {
        guard case let .join(name)? = duplicate.routes.last?.screen else { return false }
        return name.nicknameCharacterCount == 13 && name.nicknameErrorMessage == nil
          && name.nicknameValidationMessage != nil && !name.canJoin
      },
      viewport: CGSize(width: 402, height: 874)
    )

    let owner = ClassRoom.mocks[0]
    let ownerRepository = MockClassRepository(rooms: [owner], availableRooms: [])
    var ownerState = ClassCoordinator.State()
    ownerState.routes.push(.share(.init(room: owner)))
    let ownerStore = withDependencies {
      $0.uuid = .incrementing
    } operation: {
      Store(initialState: ownerState) {
        ClassCoordinator().dependency(\.classMockRepository, ownerRepository)
      }
    }
    ownerStore.send(.router(.routeAction(id: 1, action: .share(.delegate(.nameOwner(owner))))))
    ownerStore.send(.router(.routeAction(id: 2, action: .ownerName(.binding(.set(\.nickname, "김선생"))))))
    try await save(
      "join-owner-name-push",
      view: AnyView(ClassCoordinatorView(store: ownerStore)),
      ready: {
        guard case let .ownerName(name)? = ownerStore.routes.last?.screen else { return false }
        return ownerStore.routes.count == 3 && name.mode == .ownerName && name.canJoin
      }
    )

    let compact = joinStore()
    compact.send(.router(.routeAction(id: 1, action: .join(.binding(.set(\.joinCode, room.joinCode))))))
    try await save(
      "join-valid-code-push-keyboard-attempt",
      view: AnyView(ClassCoordinatorView(store: compact)),
      ready: {
        guard case let .join(code)? = compact.routes.last?.screen else { return false }
        return code.canFindClass
      },
      focusTextField: true
    )

    // Resized host on the current simulator, not a native 375x812 device screenshot.
    try await save(
      "join-valid-code-push-resized-375x812",
      view: AnyView(ClassCoordinatorView(store: compact)),
      ready: {
        guard case let .join(code)? = compact.routes.last?.screen else { return false }
        return code.canFindClass
      },
      viewport: CGSize(width: 375, height: 812)
    )
  }

  @MainActor
  func testCaptureClassDeadlineSheet() async throws {
    guard ProcessInfo.processInfo.environment["PICKE_CLASS_VISUAL_AUDIT"] == "1" else {
      throw XCTSkip("Set PICKE_CLASS_VISUAL_AUDIT=1 to capture Class deadline sheets")
    }
    let room = ClassRoom.mocks[0]
    let repository = MockClassRepository(rooms: [room], availableRooms: [])
    let directory = try FileManager.default.url(
      for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true
    ).appendingPathComponent("ClassVisualAudit", isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

    func save(
      _ name: String,
      store: StoreOf<ClassCoordinator>,
      width: CGFloat = 402,
      expectedMessage: String? = nil
    ) async throws {
      var bottomInset: CGFloat = 0
      let (image, _) = try await capture(
        AnyView(ClassCoordinatorView(store: store)),
        ready: {
          store.deadlineEdit?.room.id == room.id
            && (expectedMessage == nil
              || (store.deadlineEdit?.errorMessage ?? store.deadlineEdit?.validationMessage) == expectedMessage)
        },
        includeScrollBottom: false,
        viewport: CGSize(width: width, height: 874),
        inspectWindow: { bottomInset = $0.safeAreaInsets.bottom }
      )
      try assertDeadlinePanelGeometry(image, bottomInset: bottomInset)
      try XCTUnwrap(image.pngData()).write(to: directory.appendingPathComponent(name + ".png"))
      let attachment = XCTAttachment(image: image)
      attachment.name = name
      attachment.lifetime = .keepAlways
      add(attachment)
      let text = try recognizedAuditText(
        in: image,
        name: name,
        regionOfInterest: CGRect(x: 0, y: 0, width: 1, height: 0.5)
      )
      XCTAssertTrue(text.contains("수정하기"), "Save must be visible without scrolling: \(name)")
      XCTAssertFalse(text.contains("참여마감일수정"), "Large form header should not displace the wheel")
      if let expectedMessage {
        XCTAssertTrue(
          text.contains(expectedMessage.replacingOccurrences(of: " ", with: "")),
          "The error and save action must be visible together: \(name)"
        )
      }
    }

    func makeStore(
      _ state: ClassCoordinator.State,
      failsSave: Bool = false,
      referenceNow: Date = Date(timeIntervalSince1970: 1_760_000_000)
    ) -> StoreOf<ClassCoordinator> {
      withDependencies {
        $0.uuid = .incrementing
        $0.date.now = referenceNow
      } operation: {
        Store(initialState: state) {
          ClassCoordinator().dependency(\.classUseCase, failsSave ? MockClassRepository(rooms: []) : repository)
        }
      }
    }

    var list = MyClassFeature.State()
    list.rooms = [room]
    list.viewState = .loaded
    var listState = ClassCoordinator.State()
    listState.routes.push(.myClasses(list))
    let listStore = makeStore(listState)
    listStore.send(.router(.routeAction(id: 1, action: .myClasses(.delegate(.openInformation(room))))))
    XCTAssertEqual(listStore.routes.count, 2)
    try await save("deadline-sheet-list-compact", store: listStore)
    listStore.send(.deadlineEdit(.presented(.binding(.set(
      \.draftDeadline, room.deadline.addingTimeInterval(3600)
    )))))
    try await save("deadline-sheet-changed-375", store: listStore, width: 375)
    listStore.send(.deadlineEdit(.presented(.view(.deadlineEnabledChanged(false)))))
    try await save("deadline-sheet-toggle-off", store: listStore)

    var detailState = ClassCoordinator.State()
    detailState.routes.push(.detail(.init(room: room)))
    let detailStore = makeStore(detailState)
    detailStore.send(.router(.routeAction(id: 1, action: .detail(.delegate(.openDeadline(room))))))
    XCTAssertEqual(detailStore.routes.count, 2)
    try await save("deadline-sheet-detail-compact", store: detailStore)

    detailState.routes.push(.ownerDashboard(.init(room: room, instanceID: UUID())))
    let dashboardStore = makeStore(detailState)
    dashboardStore.send(.router(.routeAction(id: 2, action: .ownerDashboard(.delegate(.editClass)))))
    XCTAssertEqual(dashboardStore.routes.count, 3)
    try await save("deadline-sheet-dashboard-compact", store: dashboardStore)

    let pastStore = makeStore(listState, referenceNow: room.deadline.addingTimeInterval(86400))
    pastStore.send(.router(.routeAction(id: 1, action: .myClasses(.delegate(.openInformation(room))))))
    try await save(
      "deadline-sheet-validation",
      store: pastStore,
      expectedMessage: "현재 이후 시간을 선택해 주세요."
    )

    let failingStore = makeStore(listState, failsSave: true)
    failingStore.send(.router(.routeAction(id: 1, action: .myClasses(.delegate(.openInformation(room))))))
    failingStore.send(.deadlineEdit(.presented(.binding(.set(
      \.draftDeadline, room.deadline.addingTimeInterval(3600)
    )))))
    failingStore.send(.deadlineEdit(.presented(.view(.saveTapped))))
    try await save(
      "deadline-sheet-save-error",
      store: failingStore,
      expectedMessage: ClassError.invalidCode.message
    )

    var tabState = MainTabCoordinator.State(selectedTab: MainTabCoordinator.Tab.classroom.rawValue)
    tabState.classState = listState
    let tabStore = withDependencies {
      $0.context = .test
      $0.uuid = .incrementing
      $0.date.now = Date(timeIntervalSince1970: 1_760_000_000)
    } operation: {
      Store(initialState: tabState) {
        MainTabCoordinator()
          .dependency(\.classUseCase, repository)
          .dependency(\.classMockRepository, repository)
          .dependency(\.classMockChatSession, ClassMockChatSession())
          .dependency(\.classMockAudioPlayer, ClassMockAudioPlayer())
      }
    }
    var tabBottomInset: CGFloat = 0
    let (tabImage, _) = try await capture(
      AnyView(MainTabView(store: tabStore).task {
        tabStore.send(.classroom(.router(.routeAction(
          id: 1, action: .myClasses(.delegate(.openInformation(room)))
        ))))
      }),
      ready: { tabStore.classState.deadlineEdit != nil && tabStore.shouldHideTabBar },
      includeScrollBottom: false,
      inspectWindow: { tabBottomInset = $0.safeAreaInsets.bottom }
    )
    XCTAssertTrue(tabStore.shouldHideTabBar)
    try assertDeadlinePanelGeometry(tabImage, bottomInset: tabBottomInset)
    let tabAttachment = XCTAttachment(image: tabImage)
    tabAttachment.name = "deadline-sheet-tab-hosted"
    tabAttachment.lifetime = .keepAlways
    add(tabAttachment)
  }

  private func assertDeadlinePanelGeometry(
    _ image: UIImage,
    bottomInset: CGFloat
  ) throws {
    let top = image.size.height - bottomInset - 300
    func pixel(
      _ x: CGFloat,
      _ y: CGFloat
    ) throws -> [UInt8] {
      let source = try XCTUnwrap(image.cgImage)
      let crop = try XCTUnwrap(source.cropping(to: CGRect(
        x: x * image.scale, y: y * image.scale, width: 1, height: 1
      )))
      var bytes = [UInt8](repeating: 0, count: 4)
      try bytes.withUnsafeMutableBytes { buffer in
        let context = try XCTUnwrap(CGContext(
          data: buffer.baseAddress, width: 1, height: 1,
          bitsPerComponent: 8, bytesPerRow: 4,
          space: CGColorSpaceCreateDeviceRGB(),
          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ))
        context.draw(crop, in: CGRect(x: 0, y: 0, width: 1, height: 1))
      }
      return bytes
    }
    func white(
      _ x: CGFloat,
      _ y: CGFloat
    ) throws {
      let color = try pixel(x, y)
      XCTAssertTrue(color.prefix(3).allSatisfy { $0 > 245 }, "Expected sheet white at \(x),\(y): \(color)")
    }
    try white(0, top + 40)
    try white(image.size.width - 1 / image.scale, top + 40)
    try white(0, image.size.height - 1 / image.scale)
    try white(image.size.width / 2, image.size.height - 1 / image.scale)
    try white(image.size.width / 2, top + 2)
    let dim = try pixel(image.size.width / 2, top - 2)
    XCTAssertTrue(dim.prefix(3).contains { $0 < 230 }, "Panel must not extend above its specified height")
    // CTA is y240...292 from panel top, with 16pt side padding in every state.
    for y in [top + 241, top + 291] {
      let fill = try pixel(20, y)
      XCTAssertGreaterThan(Int(fill[0]) - Int(fill[1]), 10, "Expected CTA fill at y=\(y)")
    }
    try white(8, top + 266)
    try white(image.size.width - 8, top + 266)
    try white(20, top + 238)
    try white(20, top + 294)
  }

  @MainActor
  func testPresentClassShareForInteractiveAudit() async throws {
    guard ProcessInfo.processInfo.environment["PICKE_CLASS_SHARE_INTERACTIVE_AUDIT"] == "1" else {
      throw XCTSkip("Set PICKE_CLASS_SHARE_INTERACTIVE_AUDIT=1 for a manual copy check")
    }
    let room = ClassRoom.mocks[0]
    let store = Store(initialState: ClassShareFeature.State(room: room)) {
      ClassShareFeature()
    }
    let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
    let window = UIWindow(windowScene: scene)
    window.rootViewController = UIHostingController(rootView: ClassShareView(store: store))
    window.frame = scene.coordinateSpace.bounds
    window.makeKeyAndVisible()
    defer { window.isHidden = true }
    // Do not read or restore another app's clipboard. The simulator keeps the test code.
    let baseline = UIPasteboard.general.changeCount
    var copied = false
    for _ in 0 ..< 1200 {
      if UIPasteboard.general.changeCount > baseline {
        copied = UIPasteboard.general.string == room.joinCode
        break
      }
      try await Task.sleep(for: .milliseconds(100))
    }
    XCTAssertTrue(copied, "Class share copy was not observed")
  }

  @MainActor
  func testCaptureClassShareControls() async throws {
    guard ProcessInfo.processInfo.environment["PICKE_CLASS_VISUAL_AUDIT"] == "1" else {
      throw XCTSkip("Set PICKE_CLASS_VISUAL_AUDIT=1 to capture share controls")
    }
    let directory = try FileManager.default.url(
      for: .documentDirectory,
      in: .userDomainMask,
      appropriateFor: nil,
      create: true
    ).appendingPathComponent("ClassVisualAudit", isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    for viewport in [CGSize(width: 402, height: 874), CGSize(width: 375, height: 667)] {
      let store = Store(initialState: ClassShareFeature.State(room: ClassRoom.mocks[0])) {
        ClassShareFeature()
      }
      let name = "share-controls-\(Int(viewport.width))"
      let (image, _) = try await capture(
        AnyView(ClassShareView(store: store)),
        ready: nil,
        includeScrollBottom: false,
        viewport: viewport
      )
      try XCTUnwrap(image.pngData()).write(to: directory.appendingPathComponent(name + ".png"))
      let attachment = XCTAttachment(image: image)
      attachment.name = name
      attachment.lifetime = .keepAlways
      add(attachment)
      let text = try recognizedAuditText(in: image, name: name)
      XCTAssertTrue(text.contains("멤버들에게공유해주세요"))
      XCTAssertTrue(text.contains("클래스로이동하기"))
    }
  }

  @MainActor
  func testCaptureClassStartGuides() async throws {
    guard ProcessInfo.processInfo.environment["PICKE_CLASS_VISUAL_AUDIT"] == "1" else {
      throw XCTSkip("Set PICKE_CLASS_VISUAL_AUDIT=1 to capture start guides")
    }
    let directory = try FileManager.default.url(
      for: .documentDirectory,
      in: .userDomainMask,
      appropriateFor: nil,
      create: true
    ).appendingPathComponent("ClassVisualAudit", isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

    // The compact host checks layout; it is not a native 375pt device capture.
    for viewport in [CGSize(width: 402, height: 874), CGSize(width: 375, height: 667)] {
      for kind in [ClassStartGuideKind.pickeBattle, .customBattle] {
        let store = Store(initialState: ClassStartMethodFeature.State()) {
          ClassStartMethodFeature()
        }
        store.send(.view(.guideTapped(kind)))
        let slug = kind == .pickeBattle ? "picke" : "custom"
        let name = "start-guide-\(slug)-\(Int(viewport.width))"
        let (image, _) = try await capture(
          AnyView(ClassStartMethodView(store: store)),
          ready: { store.guide?.kind == kind },
          includeScrollBottom: false,
          viewport: viewport
        )
        try XCTUnwrap(image.pngData()).write(to: directory.appendingPathComponent(name + ".png"))
        let attachment = XCTAttachment(image: image)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
        let text = try recognizedAuditText(in: image, name: name)
        XCTAssertTrue(text.contains("이용가이드"))
        XCTAssertTrue(text.contains("확인했어요"))
        XCTAssertTrue(text.contains(kind == .pickeBattle ? "준비된콘텐츠와오디오로바로토론해요" : "우리만의주제로AI와토론해요"))
        XCTAssertEqual(store.selectedMethod, .existingContent)
        store.send(.guide(.presented(.dismissTapped)))
        XCTAssertNil(store.guide)
      }

      let store = Store(initialState: ClassStartMethodFeature.State()) {
        ClassStartMethodFeature()
      }
      let name = "start-method-guides-\(Int(viewport.width))"
      let (image, _) = try await capture(
        AnyView(ClassStartMethodView(store: store)),
        ready: nil,
        includeScrollBottom: false,
        viewport: viewport
      )
      try XCTUnwrap(image.pngData()).write(to: directory.appendingPathComponent(name + ".png"))
      let attachment = XCTAttachment(image: image)
      attachment.name = name
      attachment.lifetime = .keepAlways
      add(attachment)
    }
  }

  @MainActor
  func testCaptureClassSettingLineBoxes() async throws {
    guard ProcessInfo.processInfo.environment["PICKE_CLASS_VISUAL_AUDIT"] == "1" else {
      throw XCTSkip("Set PICKE_CLASS_VISUAL_AUDIT=1 to capture setting line boxes")
    }
    let directory = try FileManager.default.url(
      for: .documentDirectory,
      in: .userDomainMask,
      appropriateFor: nil,
      create: true
    ).appendingPathComponent("ClassVisualAudit", isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let room = ClassRoom.mocks[0]
    let standard = ClassSettingFeature.State(battle: room.battle, deadline: room.deadline)
    var longName = standard
    longName.name = "함께 생각을 나누는 2학년 3반 토론 클래스"
    longName.isDeadlineEnabled = false
    let ai = ClassSettingFeature.State(
      aiQuestion: ClassAIQuestion.examples[0],
      filter: ClassTopicFilter(categories: [.philosophy]),
      deadline: room.deadline
    )
    // The 375 host is a layout check, not a native compact-device screenshot.
    // AI copy is compared with the 1x Figma reference at node 12772:36100.
    let cases: [(String, ClassSettingFeature.State, CGSize)] = [
      ("setting-lineboxes-402", standard, CGSize(width: 402, height: 874)),
      ("setting-lineboxes-375", standard, CGSize(width: 375, height: 667)),
      ("setting-long-name-deadline-off", longName, CGSize(width: 402, height: 874)),
      ("setting-ai-402", ai, CGSize(width: 402, height: 874)),
      ("setting-ai-375", ai, CGSize(width: 375, height: 667)),
    ]
    for (name, state, viewport) in cases {
      let store = Store(initialState: state) { ClassSettingFeature() }
      let (image, bottomImage) = try await capture(
        AnyView(ClassSettingView(store: store)),
        ready: nil,
        includeScrollBottom: name.hasPrefix("setting-lineboxes-") || name.hasPrefix("setting-ai-"),
        viewport: viewport
      )
      for (suffix, captured) in [("", image), ("-bottom", bottomImage)].compactMap({ suffix, value in
        value.map { (suffix, $0) }
      }) {
        let imageName = name + suffix
        try XCTUnwrap(captured.pngData()).write(to: directory.appendingPathComponent(imageName + ".png"))
        let attachment = XCTAttachment(image: captured)
        attachment.name = imageName
        attachment.lifetime = .keepAlways
        add(attachment)
        let text = try recognizedAuditText(in: captured, name: imageName)
        XCTAssertTrue(text.contains("클래스설정"))
        XCTAssertTrue(text.contains("클래스만들기"))
        if name.hasPrefix("setting-ai-") {
          if suffix.isEmpty {
            XCTAssertTrue(text.contains("거의다왔어요!"))
            XCTAssertTrue(text.contains("클래스정보를입력해주세요"))
          } else {
            XCTAssertTrue(text.contains("댓글달기필수"))
            XCTAssertTrue(text.contains("멤버의생각을댓글로확인해요"))
            XCTAssertTrue(text.contains("나도참여하기"))
            XCTAssertFalse(text.contains("운영자참여"))
          }
        }
      }
    }
  }

  @MainActor
  func testClassParticipatedVotePresentationAndBack() async throws {
    guard ProcessInfo.processInfo.environment["PICKE_CLASS_VISUAL_AUDIT"] == "1" else {
      throw XCTSkip("Set PICKE_CLASS_VISUAL_AUDIT=1 to verify participated vote navigation")
    }
    // 375pt is a resized host, not a native device. Both variants use the same
    // mounted coordinator for summary -> result/comment -> original Class detail.
    let scenarios: [(String, CGSize, Bool)] = [
      ("375", CGSize(width: 375, height: 812), false),
      ("402", CGSize(width: 402, height: 874), false),
      ("375-compact", CGSize(width: 375, height: 667), false),
      ("375-compact-long", CGSize(width: 375, height: 667), true),
      ("402-long", CGSize(width: 402, height: 874), true),
    ]
    for (suffix, viewport, longContent) in scenarios {
      let room = participatedAuditRoom(longContent: longContent)
      let session = ClassMockChatSession()
      let battleID = await session.register(room: room)
      let battleAPI: any BattleInterface = session
      _ = try await battleAPI.submitPreVote(battleId: battleID, optionId: 1)
      _ = try await battleAPI.submitPostVote(battleId: battleID, optionId: 1)
      // Deliberately no perspective: final-voted participants still see results.
      let repository = MockClassRepository(rooms: [room], availableRooms: [])
      var preVote = PreVoteFeature.State(battleId: battleID)
      preVote.showsResultsForExistingParticipation = true
      var chat = ChatCoordinator.State(route: .preVote(battleId: battleID))
      chat.routes[screenAt: 0] = .preVote(preVote)
      var state = ClassCoordinator.State()
      state.routes.push(.detail(.init(room: room)))
      state.routes.push(.chat(chat))
      state.chatRoomsByBattleID[battleID] = room
      let store = Store(initialState: state) {
        ClassCoordinator()
          .dependency(\.classUseCase, repository)
          .dependency(\.classMockRepository, repository)
          .dependency(\.classMockChatSession, session)
          .dependency(\.classMockAudioPlayer, ClassMockAudioPlayer())
          .dependency(\.battleUseCase, session)
          .dependency(\.perspectiveUseCase, session)
          .dependency(\.commentUseCase, session)
          .dependency(\.analyticsUseCase, .testValue)
          .dependency(\.shareUseCase, .testValue)
      }
      let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
      let window = UIWindow(windowScene: scene)
      let host = UIHostingController(rootView: ClassCoordinatorView(store: store))
      window.rootViewController = host
      window.frame = CGRect(origin: .zero, size: viewport)
      window.makeKeyAndVisible()
      defer { window.isHidden = true }
      try await waitForClassAudit("participated summary without a perspective") {
        guard case let .chat(chat)? = store.routes.last?.screen,
              case let .preVote(vote)? = chat.routes.first?.screen else { return false }
        return vote.isShowingParticipationResult && vote.battle != nil && !vote.isCheckingParticipation
      }
      let name = "participated-vote-\(suffix)"
      let image = try await saveClassAudit(window: window, name: name)
      let text = try recognizedAuditText(in: image, name: name)
      XCTAssertTrue(text.contains("결과보기"), "Result CTA is missing: \(text)")
      XCTAssertFalse(text.contains("사전투표하기"))
      XCTAssertFalse(text.contains("VS"), "Completed summary must omit the option row")
      XCTAssertFalse(store.showsTabBar)
      if longContent {
        XCTAssertTrue(text.contains("긴제목검증"))
        try assertParticipatedHeaderSeparation(image: image, roomName: room.name)
        let scrollCandidates = verticalScrollViews(in: host.view, window: window)
        if scrollCandidates.isEmpty {
          print("Participated scroll diagnostics: \(scrollDiagnostics(in: host.view, window: window))")
        }
        let scrollView = try XCTUnwrap(scrollCandidates.max {
          $0.bounds.height < $1.bounds.height
        }, "Long participated content must expose a scrollable region")
        let bottomOffset = scrollView.contentSize.height - scrollView.bounds.height
          + scrollView.adjustedContentInset.bottom
        XCTAssertGreaterThan(bottomOffset, scrollView.contentOffset.y + 1)
        scrollView.setContentOffset(
          CGPoint(x: scrollView.contentOffset.x, y: bottomOffset),
          animated: false
        )
        let bottomName = name + "-bottom"
        let bottomImage = try await saveClassAudit(window: window, name: bottomName)
        let bottomText = try recognizedAuditText(in: bottomImage, name: bottomName)
        XCTAssertEqual(scrollView.contentOffset.y, bottomOffset, accuracy: 1)
        XCTAssertTrue(bottomText.contains("여기까지읽었습니다"), "Final summary text was clipped: \(bottomText)")
        XCTAssertTrue(bottomText.contains("결과보기"), "The fixed CTA must remain visible while scrolling")
      } else if viewport.height >= 812 {
        let scrollView = try XCTUnwrap(verticalScrollViews(
          in: host.view,
          window: window,
          requiresOverflow: false
        ).max { $0.bounds.height < $1.bounds.height }, "Expected the participated summary scroll view")
        let overflow = scrollView.contentSize.height + scrollView.adjustedContentInset.top
          + scrollView.adjustedContentInset.bottom - scrollView.bounds.height
        XCTAssertLessThanOrEqual(overflow, 1, "Standard summary must fit above its fixed footer")
      }
      store.send(.router(.routeAction(id: 2, action: .chat(.router(.routeAction(
        id: 0, action: .preVote(.view(.primaryButtonTapped))
      ))))))
      try await waitForClassAudit("result comment replaces summary root") {
        guard case let .chat(chat)? = store.routes.last?.screen,
              case let .comment(comment)? = chat.routes.first?.screen else { return false }
        return chat.routes.count == 1 && comment.battleId == battleID
          && !comment.title.isEmpty && !comment.isLoadingStats && !comment.isLoadingComments
      }
      let resultName = "participated-result-\(suffix)"
      let resultImage = try await saveClassAudit(window: window, name: resultName)
      let resultText = try recognizedAuditText(in: resultImage, name: resultName)
      XCTAssertTrue(resultText.contains("리포트"), "Class comment/report entry is missing: \(resultText)")
      XCTAssertFalse(resultText.contains("결과보기"))
      store.send(.router(.routeAction(id: 2, action: .chat(.router(.routeAction(
        id: 0, action: .comment(.view(.backButtonTapped))
      ))))))
      try await waitForClassAudit("same Class detail after result back") {
        guard case let .detail(detail)? = store.routes.last?.screen else { return false }
        return store.routes.count == 2 && detail.room.id == room.id && store.showsTabBar
      }
      let backName = "participated-back-detail-\(suffix)"
      let backImage = try await saveClassAudit(window: window, name: backName)
      let backText = try recognizedAuditText(in: backImage, name: backName)
      XCTAssertTrue(backText.contains("클래스상세"))
    }
  }

  @MainActor
  func testClassRecommendLayout() async throws {
    guard ProcessInfo.processInfo.environment["PICKE_CLASS_VISUAL_AUDIT"] == "1" else {
      throw XCTSkip("Set PICKE_CLASS_VISUAL_AUDIT=1 to verify recommendation layout")
    }
    // Local fixture: the shared Class/AI-setting filter below stays unchanged.
    let topic = "AI와 인간 사이의 윤리와 사상에 대해서"
    let scenarios: [(String, ClassRecommendFeature.Mode, CGSize, String)] = [
      ("ai-402", .aiQuestions, CGSize(width: 402, height: 874), topic),
      ("ai-375", .aiQuestions, CGSize(width: 375, height: 812), topic),
      ("existing-402", .existingContent, CGSize(width: 402, height: 874), topic),
      ("existing-375", .existingContent, CGSize(width: 375, height: 812), topic),
      ("ai-no-topic-402", .aiQuestions, CGSize(width: 402, height: 874), ""),
    ]
    for (suffix, mode, viewport, keyword) in scenarios {
      var state = ClassRecommendFeature.State(
        filter: .init(keyword: keyword, level: .middle, categories: [.philosophy, .society]),
        mode: mode
      )
      state.questions = Array(ClassAIQuestion.examples.prefix(3))
      state.battles = ClassBattleSummary.mocks.filter { $0.level == .middle && $0.category == .philosophy }
      state.viewState = .loaded
      let store = Store(initialState: state) { ClassRecommendFeature() }
      let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
      let window = UIWindow(windowScene: scene)
      let host = UIHostingController(rootView: ClassRecommendView(store: store))
      window.rootViewController = host
      window.frame = CGRect(origin: .zero, size: viewport)
      window.makeKeyAndVisible()
      defer { window.isHidden = true }
      let name = "recommend-" + suffix
      let initialImage = try await saveClassAudit(window: window, name: name + "-unselected")
      let initialText = try recognizedAuditText(
        in: initialImage,
        name: name + "-unselected"
      )
      XCTAssertFalse(store.canSelect)
      try assertRecommendCTA(in: initialImage, name: name + "-unselected")
      XCTAssertTrue(initialText.contains("선택한조건"))
      XCTAssertEqual(store.conditionTitles.count, keyword.isEmpty ? 3 : 4)
      if !keyword.isEmpty {
        XCTAssertTrue(initialText.contains("AI와인간사이의윤리와사상에대해서"))
      }

      if mode == .aiQuestions {
        try store.send(.view(.questionTapped(XCTUnwrap(state.questions.first).id)))
      } else {
        try store.send(.view(.battleTapped(XCTUnwrap(state.battles.first).id)))
      }
      XCTAssertTrue(store.canSelect)
      let selectedImage = try await saveClassAudit(window: window, name: name + "-selected")
      XCTAssertNotEqual(initialImage.pngData(), selectedImage.pngData(), "Selection must visibly update card and CTA")
      guard !keyword.isEmpty else { continue }

      let chips = try XCTUnwrap(horizontalClassAuditScrollViews(in: host.view, window: window).first)
      let chipFrame = chips.convert(chips.bounds, to: window).intersection(window.bounds)
      let readableChipFrame = CGRect(
        x: chipFrame.minX,
        y: chipFrame.minY,
        width: chipFrame.width - 60,
        height: chipFrame.height
      )
      XCTAssertGreaterThan(readableChipFrame.width, 0)
      let chipRegion = CGRect(
        x: readableChipFrame.minX / window.bounds.width,
        y: 1 - readableChipFrame.maxY / window.bounds.height,
        width: readableChipFrame.width / window.bounds.width,
        height: readableChipFrame.height / window.bounds.height
      )
      let initialChipText = try recognizedAuditText(
        in: initialImage,
        name: name + "-first-chip-region",
        regionOfInterest: chipRegion
      )
      XCTAssertFalse(initialChipText.contains("사회"), "The last chip must be outside the initial visible strip")
      let trailingOffset = chips.contentSize.width - chips.bounds.width + chips.adjustedContentInset.right
      XCTAssertGreaterThan(trailingOffset, chips.contentOffset.x + 1)
      chips.setContentOffset(CGPoint(x: trailingOffset, y: chips.contentOffset.y), animated: false)
      let chipImage = try await saveClassAudit(window: window, name: name + "-last-chip")
      let chipText = try recognizedAuditText(
        in: chipImage,
        name: name + "-last-chip-region",
        regionOfInterest: chipRegion
      )
      XCTAssertEqual(chips.contentOffset.x, trailingOffset, accuracy: 1)
      XCTAssertTrue(chipText.contains("사회"), "Last condition should scroll clear of the reset overlay")

      let list = try XCTUnwrap(verticalScrollViews(in: host.view, window: window).max {
        $0.bounds.height < $1.bounds.height
      })
      let bottomOffset = list.contentSize.height - list.bounds.height + list.adjustedContentInset.bottom
      list.setContentOffset(CGPoint(x: list.contentOffset.x, y: bottomOffset), animated: false)
      let bottomImage = try await saveClassAudit(window: window, name: name + "-last-card")
      let bottomText = try recognizedAuditText(
        in: bottomImage,
        name: name + "-last-card"
      )
      let finalTitle = try XCTUnwrap(mode == .aiQuestions ? state.questions.last?.title : state.battles.last?.title)
      XCTAssertEqual(list.contentOffset.y, bottomOffset, accuracy: 1)
      XCTAssertTrue(bottomText.contains(String(finalTitle.filter { !$0.isWhitespace }.prefix(8))),
                    "Last card should be readable above CTA: \(bottomText)")
      try assertRecommendCTA(in: bottomImage, name: name + "-last-card")
    }
  }

  @MainActor
  private func assertRecommendCTA(
    in image: UIImage,
    name: String
  ) throws {
    // Read the fixed footer independently: whole-page language correction can
    // replace the rendered domain word "배틀" with the more common "배를".
    let text = try recognizedAuditText(
      in: image,
      name: name + "-cta",
      usesLanguageCorrection: false,
      regionOfInterest: CGRect(x: 0, y: 0, width: 1, height: 0.2)
    )
    XCTAssertTrue(text.contains("배틀선택하기"), "Missing fixed CTA in bottom 20%: \(text)")
  }

  @MainActor
  private func horizontalClassAuditScrollViews(
    in view: UIView,
    window: UIWindow
  ) -> [UIScrollView] {
    guard !view.isHidden, view.alpha > 0.01 else { return [] }
    let nested = view.subviews.flatMap { horizontalClassAuditScrollViews(in: $0, window: window) }
    guard let scroll = view as? UIScrollView,
          scroll.window === window,
          scroll.bounds.height > 0,
          scroll.contentSize.width + scroll.adjustedContentInset.left + scroll.adjustedContentInset.right
          > scroll.bounds.width + 1 else { return nested }
    return [scroll] + nested
  }

  @MainActor
  func testCaptureOwnerDetailRoutes() async throws {
    guard ProcessInfo.processInfo.environment["PICKE_CLASS_VISUAL_AUDIT"] == "1" else {
      throw XCTSkip("Set PICKE_CLASS_VISUAL_AUDIT=1 to capture owner detail routes")
    }
    let room = ClassRoom.mocks[0]
    let member = ClassOwnerMember(id: 1, name: "생각하는 나무늘보", participationCount: 1)
    let opinion = ClassOwnerOpinion(
      id: 1,
      author: member.name,
      text: "감정을 표현하는 방식은 사람마다 다를 수 있다고 생각해요.",
      replyCount: 1
    )
    let emptyOpinion = ClassOwnerOpinion(
      id: 2,
      author: member.name,
      text: opinion.text,
      replyCount: 0
    )
    let replies: [ClassReplyDetailFeature.State.Reply] = [
      .init(
        id: 1,
        author: "다른 관점도 꼼꼼하게 생각하는 나무늘보",
        body: "감정을 표현하는 방식이 다르다는 점에 동의해요. 다만 함께 살아가는 사회에서는 상대가 어떻게 받아들일지도 생각해야 하지 않을까요? 서로의 상황을 이해하려는 노력이 중요하다고 생각합니다.",
        date: "2026.10.14"
      ),
    ]
    let loadedOpinion = ClassOwnerOpinion(
      id: 3,
      author: member.name,
      text: opinion.text,
      replyCount: replies.count,
      recommendationCount: 1340
    )
    var feedback = ClassFeedbackComposeFeature.State(room: room, memberName: member.name)
    feedback.feedback = "다른 관점의 근거도 비교해 보세요."
    let screens: [(String, ClassCoordinator.ClassScreen.State)] = [
      ("owner-member-detail-unavailable", .ownerMemberDetail(.init(room: room, member: member))),
      ("owner-reply-detail-unavailable", .ownerReplyDetail(.init(room: room, opinion: opinion))),
      ("owner-reply-detail-empty", .ownerReplyDetail(.init(room: room, opinion: emptyOpinion))),
      (
        "owner-reply-detail-loaded",
        .ownerReplyDetail(.init(
          room: room,
          opinion: loadedOpinion,
          replies: replies
        ))
      ),
      ("owner-feedback-empty", .ownerFeedback(.init(room: room, memberName: member.name))),
      ("owner-feedback-filled", .ownerFeedback(feedback)),
    ]
    for (name, screen) in screens {
      var state = ClassCoordinator.State()
      state.routes.push(screen)
      let repository = MockClassRepository(rooms: [room], availableRooms: [])
      let store = Store(initialState: state) {
        ClassCoordinator()
          .dependency(\.classUseCase, repository)
          .dependency(\.classMockRepository, repository)
          .dependency(\.classMockChatSession, ClassMockChatSession())
          .dependency(\.classMockAudioPlayer, ClassMockAudioPlayer())
          .dependency(\.classAIFeedbackUseCase, Self.visualAIFeedbackUseCase())
      }
      let (image, _) = try await capture(
        AnyView(ClassCoordinatorView(store: store)),
        ready: nil,
        includeScrollBottom: false
      )
      let attachment = XCTAttachment(image: image)
      attachment.name = name + ".png"
      attachment.lifetime = .keepAlways
      add(attachment)
    }
  }

  @MainActor
  func testCaptureSharedAudioPlaybackRates() async throws {
    guard ProcessInfo.processInfo.environment["PICKE_CLASS_VISUAL_AUDIT"] == "1" else {
      throw XCTSkip("Set PICKE_CLASS_VISUAL_AUDIT=1 for shared audio captures")
    }
    for rate: Float in [1, 1.25, 2] {
      // Plain ChatRoomView uses its ordinary preview scenario, without Class routing or mocks.
      var state = ChatRoomFeature.State(battleId: 901)
      state.scenario = BattleScenario(
        battleId: 901,
        title: "뒤샹의 변기, 예술인가 도발인가",
        philosophers: [],
        isInteractive: false,
        startNodeId: 1,
        recommendedPathKey: .common,
        audios: [:],
        nodes: [ScenarioNode(
          nodeId: 1,
          nodeName: "START",
          audioDuration: 268,
          autoNextNodeId: nil,
          scripts: [ScenarioScript(
            scriptId: 1,
            startTimeMs: 0,
            speakerType: .a,
            speakerName: "플라톤",
            text: "하늘 아래 모든 사물은 그에 걸맞은 목적과 형상을 가지고 있습니다."
          )],
          interactiveOptions: []
        )]
      )
      state.currentNodeId = 1
      state.visibleNodeIds = [1]
      state.currentTime = 24
      state.playbackRate = rate
      let store = Store(initialState: state) {
        ChatRoomFeature()
          .dependency(\.audioPlayer, DefaultAudioPlayerImpl())
          .dependency(\.analyticsUseCase, .testValue)
      }
      let (image, _) = try await capture(
        AnyView(ChatRoomView(store: store)),
        ready: { store.scenario != nil && !store.scenarioLoadFailed },
        includeScrollBottom: false,
        viewport: CGSize(width: 375, height: 812)
      )
      XCTAssertEqual(store.playbackRate, rate)
      let attachment = XCTAttachment(image: image)
      attachment.name = "shared-chat-audio-\(rate)x-375"
      attachment.lifetime = .keepAlways
      add(attachment)
    }
  }

  @MainActor
  func testCaptureClassFlowFrames() async throws {
    guard ProcessInfo.processInfo.environment["PICKE_CLASS_VISUAL_AUDIT"] == "1" else {
      throw XCTSkip("Set PICKE_CLASS_VISUAL_AUDIT=1 to capture the Class user flow")
    }

    let directory = try FileManager.default.url(
      for: .documentDirectory,
      in: .userDomainMask,
      appropriateFor: nil,
      create: true
    ).appendingPathComponent("ClassVisualAudit", isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

    let frames = try await withDependencies {
      $0.context = .test
      $0.uuid = .incrementing
    } operation: {
      try await makeFrames()
    }
    var records: [Record] = []
    var imageCount = 0
    for frame in frames {
      guard let view = frame.view else {
        records.append(.init(
          number: frame.number,
          title: frame.title,
          status: "unavailable",
          detail: frame.detail,
          width: nil,
          height: nil
        ))
        continue
      }
      // Generated feedback can fit entirely on a tall phone. A compact viewport
      // exercises scrolling while preserving the actual bottom/changed-pixel checks.
      let needsBottomCapture = [19, 23, 25].contains(frame.number)
      let (image, bottomImage) = try await capture(
        view,
        ready: frame.ready,
        includeScrollBottom: needsBottomCapture,
        viewport: needsBottomCapture ? CGSize(width: 402, height: 640) : nil
      )
      let name = String(format: "%02d", frame.number) + "-" + frame.slug + ".png"
      try XCTUnwrap(image.pngData()).write(to: directory.appendingPathComponent(name))
      imageCount += 1
      let attachment = XCTAttachment(image: image)
      attachment.name = name
      attachment.lifetime = .keepAlways
      add(attachment)
      if let bottomImage {
        let bottomName = String(format: "%02d", frame.number) + "-" + frame.slug + "-bottom.png"
        try XCTUnwrap(bottomImage.pngData()).write(to: directory.appendingPathComponent(bottomName))
        imageCount += 1
        let bottomAttachment = XCTAttachment(image: bottomImage)
        bottomAttachment.name = bottomName
        bottomAttachment.lifetime = .keepAlways
        add(bottomAttachment)
      }
      records.append(.init(
        number: frame.number,
        title: frame.title,
        status: "captured; visual comparison pending",
        detail: frame.detail,
        width: image.cgImage?.width,
        height: image.cgImage?.height
      ))
    }

    let manifest = try JSONEncoder().encode(records)
    try manifest.write(to: directory.appendingPathComponent("manifest.json"))
    XCTAssertEqual(records.count, 28)
    XCTAssertEqual(records.filter { $0.status == "captured; visual comparison pending" }.count, 28)
    XCTAssertEqual(imageCount, 31)
  }

  private struct Frame {
    let number: Int
    let title: String
    let slug: String
    let detail: String
    let view: AnyView?
    let ready: (@MainActor () -> Bool)?
  }

  private struct Record: Codable {
    let number: Int
    let title: String
    let status: String
    let detail: String
    let width: Int?
    let height: Int?
  }

  private enum CaptureError: Error {
    case contentNotReady
    case scrollDidNotReachBottom
    case duplicateBottomCapture
  }

  @MainActor
  private func capture(
    _ view: AnyView,
    ready: (@MainActor () -> Bool)?,
    includeScrollBottom: Bool,
    viewport: CGSize? = nil,
    focusTextField: Bool = false,
    inspectWindow: ((UIWindow) -> Void)? = nil
  ) async throws -> (UIImage, UIImage?) {
    let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
    let window = UIWindow(windowScene: scene)
    let host = UIHostingController(rootView: view)
    window.rootViewController = host
    window.frame = CGRect(origin: .zero, size: viewport ?? scene.coordinateSpace.bounds.size)
    window.makeKeyAndVisible()
    defer { window.isHidden = true }
    host.view.frame = window.bounds
    host.view.setNeedsLayout()
    host.view.layoutIfNeeded()
    await Task.yield()
    if let ready {
      for _ in 0 ..< 50 {
        if ready() {
          break
        }
        try await Task.sleep(for: .milliseconds(100))
      }
      guard ready() else {
        XCTFail("Async content did not finish loading before capture")
        throw CaptureError.contentNotReady
      }
    }
    if focusTextField {
      let textField = firstTextField(in: host.view)
      XCTAssertNotNil(textField, "Join overlay did not expose a native text field")
      _ = textField?.becomeFirstResponder()
      try await Task.sleep(for: .milliseconds(400))
      XCTAssertTrue(textField?.isFirstResponder == true, "Join code field did not take native focus")
    }
    // The report charts animate for 0.8 seconds after their data arrives.
    try await Task.sleep(for: includeScrollBottom ? .milliseconds(800) : .milliseconds(400))
    try await Task.sleep(for: .milliseconds(17))
    host.view.layoutIfNeeded()
    CATransaction.flush()

    inspectWindow?(window)
    let renderer = UIGraphicsImageRenderer(bounds: window.bounds)
    let image = renderer.image { _ in
      window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
      if focusTextField {
        for overlay in scene.windows where overlay !== window && !overlay.isHidden
          && overlay.windowLevel > window.windowLevel
        {
          overlay.drawHierarchy(in: overlay.convert(overlay.bounds, to: window), afterScreenUpdates: true)
        }
      }
    }
    var bottomImage: UIImage?
    if includeScrollBottom {
      if verticalScrollViews(in: host.view, window: window).isEmpty {
        let attachment = XCTAttachment(image: image)
        attachment.name = "missing-scroll-view-top"
        attachment.lifetime = .keepAlways
        add(attachment)
      }
      let scrollView = try XCTUnwrap(verticalScrollViews(in: host.view, window: window).max {
        $0.bounds.height < $1.bounds.height
      },
      "Expected visible report content to have a vertical scroll view: \(scrollDiagnostics(in: host.view, window: window))")
      let bottomOffset = max(
        -scrollView.adjustedContentInset.top,
        scrollView.contentSize.height - scrollView.bounds.height + scrollView.adjustedContentInset.bottom
      )
      guard bottomOffset > scrollView.contentOffset.y + 1 else {
        XCTFail("Report scroll view has no uncaptured content below the current viewport")
        throw CaptureError.scrollDidNotReachBottom
      }
      scrollView.setContentOffset(CGPoint(
        x: scrollView.contentOffset.x,
        y: bottomOffset
      ), animated: false)
      try await Task.sleep(for: .milliseconds(100))
      host.view.layoutIfNeeded()
      guard abs(scrollView.contentOffset.y - bottomOffset) <= 1 else {
        XCTFail("Report scroll view did not reach its bottom offset")
        throw CaptureError.scrollDidNotReachBottom
      }
      CATransaction.flush()
      bottomImage = renderer.image { _ in
        window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
      }
      let topPixels = try XCTUnwrap(image.cgImage?.dataProvider?.data) as Data
      let bottomPixels = try XCTUnwrap(bottomImage?.cgImage?.dataProvider?.data) as Data
      guard topPixels != bottomPixels else {
        XCTFail("Report bottom capture is identical to its top capture")
        throw CaptureError.duplicateBottomCapture
      }
    }
    return (image, bottomImage)
  }

  @MainActor
  private func firstTextField(in view: UIView) -> UITextField? {
    if let field = view as? UITextField {
      return field
    }
    return view.subviews.lazy.compactMap(firstTextField(in:)).first
  }

  @MainActor
  private func verticalScrollViews(
    in view: UIView,
    window: UIWindow,
    requiresOverflow: Bool = true
  ) -> [UIScrollView] {
    guard !view.isHidden, view.alpha > 0.01 else { return [] }
    let candidates = view.subviews.flatMap {
      verticalScrollViews(in: $0, window: window, requiresOverflow: requiresOverflow)
    }
    guard let scrollView = view as? UIScrollView,
          scrollView.window === window,
          scrollView.bounds.height > 0,
          !requiresOverflow || scrollView.contentSize.height + scrollView.adjustedContentInset.top
          + scrollView.adjustedContentInset.bottom > scrollView.bounds.height + 1
    else { return candidates }
    let visibleFrame = scrollView.convert(scrollView.bounds, to: window).intersection(window.bounds)
    guard !visibleFrame.isNull, !visibleFrame.isEmpty,
          let hitView = window.hitTest(CGPoint(x: visibleFrame.midX, y: visibleFrame.midY), with: nil),
          hitView === scrollView || hitView.isDescendant(of: scrollView) else { return candidates }
    return [scrollView] + candidates
  }

  private func scrollDiagnostics(
    in view: UIView,
    window: UIWindow
  ) -> [String] {
    let nested = view.subviews.flatMap { scrollDiagnostics(in: $0, window: window) }
    guard let scroll = view as? UIScrollView else { return nested }
    let visible = scroll.convert(scroll.bounds, to: window).intersection(window.bounds)
    let hit = window.hitTest(CGPoint(x: visible.midX, y: visible.midY), with: nil)
    return [
      "\(type(of: scroll)) bounds=\(scroll.bounds) content=\(scroll.contentSize) hidden=\(scroll.isHidden) alpha=\(scroll.alpha) window=\(scroll.window === window) visible=\(visible) hit=\(String(describing: hit)) descendant=\(hit?.isDescendant(of: scroll) ?? false)",
    ] +
      nested
  }

  private func participatedAuditRoom(longContent: Bool) -> ClassRoom {
    let room = ClassRoom.mockJoinable
    guard longContent else { return room }
    let source = room.battle
    let battle = ClassBattleSummary(
      id: source.id,
      title: "긴 제목 검증 " + Array(repeating: source.title, count: 3).joined(separator: " "),
      summary: Array(repeating: source.summary, count: 20).joined(separator: " ") + " 여기까지 읽었습니다.",
      thumbnailURL: source.thumbnailURL,
      philosopherA: source.philosopherA,
      optionATitle: source.optionATitle,
      optionADescription: source.optionADescription,
      philosopherAImageURL: source.philosopherAImageURL,
      philosopherB: source.philosopherB,
      optionBTitle: source.optionBTitle,
      optionBDescription: source.optionBDescription,
      philosopherBImageURL: source.philosopherBImageURL,
      category: source.category,
      categoryDisplayTitle: source.categoryDisplayTitle,
      level: source.level,
      audioDuration: source.audioDuration,
      viewCount: source.viewCount,
      commentCount: source.commentCount
    )
    return ClassRoom(
      id: room.id,
      name: room.name,
      joinCode: room.joinCode,
      battle: battle,
      deadline: room.deadline,
      memberCount: room.memberCount,
      role: room.role,
      status: room.status,
      allowsAnonymousOpinion: room.allowsAnonymousOpinion,
      requiresComment: room.requiresComment,
      ownerParticipates: room.ownerParticipates
    )
  }

  private func assertParticipatedHeaderSeparation(
    image: UIImage,
    roomName: String
  ) throws {
    let request = VNRecognizeTextRequest()
    request.recognitionLevel = .accurate
    request.recognitionLanguages = ["ko-KR", "en-US"]
    let handler = try VNImageRequestHandler(cgImage: XCTUnwrap(image.cgImage))
    try handler.perform([request])
    let observations = request.results ?? []
    let header = try XCTUnwrap(observations.first {
      $0.topCandidates(1).first?.string.filter { !$0.isWhitespace }
        .contains(roomName.filter { !$0.isWhitespace }) == true
    }, "The fixed Class header must remain visible")
    let title = try XCTUnwrap(observations.first {
      $0.topCandidates(1).first?.string.filter { !$0.isWhitespace }.contains("긴제목검증") == true
    }, "The long title must remain visible below the header")
    XCTAssertLessThan(title.boundingBox.maxY, header.boundingBox.minY,
                      "Navigation title and body title must occupy separate lines")
  }

  private static var visualPersonalFeedback: ClassAIPersonalFeedback {
    ClassAIPersonalFeedback(
      summaryTitle: "생각의 흐름",
      summaryDetail: "처음 선택한 근거와 마지막 판단을 연결해 봤어요.",
      points: [
        .init(title: "처음 관점", detail: "처음에는 선택의 이유를 분명히 적었어요."),
        .init(title: "새로운 근거", detail: "다른 의견을 읽고 비교할 지점을 찾았어요."),
        .init(title: "다음 생각", detail: "다음에는 반대 의견의 근거도 살펴보세요."),
      ],
      nextQuestion: "서로 다른 근거를 어떻게 비교할까요?",
      nextHint: "친구의 의견에서 한 가지 근거를 골라 보세요."
    )
  }

  @MainActor
  private static func visualAIFeedbackUseCase() -> MockClassAIFeedbackUseCase {
    MockClassAIFeedbackUseCase { context in
      switch context.kind {
      case .classInsight:
        return .classInsight("서로 다른 의견을 비교하며 근거를 살펴봤어요.")
      case .studentPersonal, .ownerPersonal:
        return .personal(Self.visualPersonalFeedback)
      }
    }
  }

  @MainActor
  private func makeFrames() async throws -> [Frame] {
    let owner = ClassRoom.mocks[0]
    let member = ClassRoom.mockJoinable
    let aiQuestion = ClassAIQuestion.examples[0]
    let filter = ClassTopicFilter(categories: [.philosophy])
    var topic = ClassTopicFeature.State()
    topic.categories = [.philosophy]
    let aiBattle = try XCTUnwrap(ClassSettingFeature.State(aiQuestion: aiQuestion, filter: filter).aiBattle)
    let aiRoom = ClassRoom(
      id: 801,
      name: "AI 질문 토론 클래스",
      joinCode: "PKAI01",
      battle: aiBattle,
      deadline: owner.deadline,
      memberCount: 32,
      role: .member,
      status: .open,
      allowsAnonymousOpinion: false,
      requiresComment: false
    )
    var aiChatAlert = ClassAIChatFeature.State(room: aiRoom, battleID: -1_000_801, selectedOptionID: 1)
    aiChatAlert.isCompleted = true
    aiChatAlert.customAlert = .finalVote()
    let session = ClassMockChatSession()
    let battleID = await session.register(room: member)
    let preVoteSession = ClassMockChatSession()
    let preVoteBattleID = await preVoteSession.register(room: member)
    let battleAPI: any BattleInterface = session
    _ = try await battleAPI.createPerspective(
      battleId: battleID,
      content: "감정을 드러내는 방식은 사람마다 다를 수 있다고 생각합니다.",
      optionId: 1
    )
    let previewRepository = MockClassRepository(
      rooms: ClassRoom.mocks + [member, .mockClosedSociety],
      availableRooms: []
    )
    let ownerMembers = try await previewRepository.fetchMembers(roomID: owner.id)

    func classTab(_ screen: ClassCoordinator.ClassScreen.State) -> AnyView {
      let repository: MockClassRepository = if case let .myClasses(list) = screen {
        MockClassRepository(rooms: list.rooms, availableRooms: [])
      } else {
        previewRepository
      }
      var state = MainTabCoordinator.State(selectedTab: MainTabCoordinator.Tab.classroom.rawValue)
      state.classState.routes.push(screen)
      return AnyView(MainTabView(store: Store(initialState: state) {
        MainTabCoordinator()
          .dependency(\.classUseCase, repository)
          .dependency(\.classMockRepository, repository)
          .dependency(\.classMockChatSession, session)
          .dependency(\.classMockAudioPlayer, ClassMockAudioPlayer())
      }))
    }

    func loadedClassFrame(
      _ number: Int,
      _ title: String,
      _ slug: String,
      _ detail: String,
      _ screen: ClassCoordinator.ClassScreen.State
    ) -> Frame {
      var state = MainTabCoordinator.State(selectedTab: MainTabCoordinator.Tab.classroom.rawValue)
      state.classState.routes.push(screen)
      let store = Store(initialState: state) {
        MainTabCoordinator()
          .dependency(\.classUseCase, previewRepository)
          .dependency(\.classMockRepository, previewRepository)
          .dependency(\.classMockChatSession, session)
          .dependency(\.classMockAudioPlayer, ClassMockAudioPlayer())
          .dependency(\.classAIFeedbackUseCase, Self.visualAIFeedbackUseCase())
      }
      let ready: @MainActor () -> Bool = {
        switch store.classState.routes.last?.screen {
        case let .report(value)?:
          if case .ready = value.feedbackViewState {
            return value.sourceViewState == .ready && value.report != nil
          }
          return false
        case let .ownerDashboard(value)?:
          guard value.sourceViewState == .ready, value.report != nil, value.metrics != nil else { return false }
          if value.selectedTab == .report {
            if case .ready = value.feedbackViewState {
              return true
            }
          } else if case .ready = value.insightViewState {
            return true
          }
          return false
        default:
          return false
        }
      }
      return Frame(
        number: number,
        title: title,
        slug: slug,
        detail: detail,
        view: AnyView(MainTabView(store: store)),
        ready: ready
      )
    }

    func chatFrame(
      _ number: Int,
      _ title: String,
      _ slug: String,
      _ state: ChatCoordinator.State,
      session frameSession: ClassMockChatSession,
      battleID frameBattleID: Int
    ) -> Frame {
      let store = Store(initialState: state) {
        ChatCoordinator()
          .dependency(\.battleUseCase, frameSession)
          .dependency(\.perspectiveUseCase, frameSession)
          .dependency(\.commentUseCase, frameSession)
          .dependency(\.audioPlayer, ClassMockAudioPlayer())
          .dependency(\.analyticsUseCase, .testValue)
          .dependency(\.shareUseCase, .testValue)
      }
      let ready: @MainActor () -> Bool = {
        switch (number, store.routes.last?.screen) {
        case let (16, .preVote(value)?) where value.voteMode == .post:
          return value.battle != nil && !value.detailLoadFailed && !value.isCheckingParticipation
        case let (18, .preVote(value)?) where value.voteMode == .pre:
          return value.battle != nil && !value.detailLoadFailed && !value.isCheckingParticipation
        case let (17, .chatRoom(value)?):
          return value.scenario != nil && !value.scenarioLoadFailed
        case let (15, .comment(value)?):
          return !value.title.isEmpty && !value.isLoadingComments && !value.isLoadingStats
        default:
          return false
        }
      }
      return Frame(
        number: number,
        title: title,
        slug: slug,
        detail: "seeded member battle; async mock load",
        view: AnyView(ClassChatCoordinatorView(
          store: store,
          roomsByBattleID: [frameBattleID: member],
          onOpenReport: { _ in }
        )),
        ready: ready
      )
    }

    var chatRoom = ChatCoordinator.State(battleId: battleID)
    chatRoom.routes = [.root(.chatRoom(.init(battleId: battleID)), embedInNavigationView: true)]

    var aiRecommend = ClassRecommendFeature.State(filter: filter, mode: .aiQuestions)
    aiRecommend.questions = ClassAIQuestion.examples
    aiRecommend.viewState = .loaded
    aiRecommend.selectedQuestionId = aiQuestion.id
    var existingRecommend = ClassRecommendFeature.State(filter: filter)
    existingRecommend.battles = ClassBattleSummary.mocks
    existingRecommend.viewState = .loaded
    existingRecommend.selectedBattleId = ClassBattleSummary.mocks[0].id
    var ownerList = MyClassFeature.State()
    ownerList.rooms = ClassRoom.mocks
    ownerList.viewState = .loaded
    var memberList = MyClassFeature.State()
    memberList.rooms = memberRooms
    memberList.viewState = .loaded
    var ownerReport = ClassOwnerDashboardFeature.State(room: owner, instanceID: UUID())
    ownerReport.selectedTab = .report

    func frame(_ number: Int, _ title: String, _ slug: String, _ detail: String, _ view: AnyView?) -> Frame {
      Frame(number: number, title: title, slug: slug, detail: detail, view: view, ready: nil)
    }

    return [
      frame(
        1,
        "AI 질문 추천",
        "ai-recommend",
        "selected first AI question",
        AnyView(ClassRecommendView(store: Store(initialState: aiRecommend) { ClassRecommendFeature() }))
      ),
      frame(
        2,
        "AI 질문 설정",
        "ai-setting",
        "first AI question; empty class name",
        AnyView(ClassSettingView(store: Store(initialState: .init(aiQuestion: aiQuestion, filter: filter)) {
          ClassSettingFeature()
        }))
      ),
      frame(
        3,
        "홈",
        "home",
        "real Home tab; login and async data may limit content",
        AnyView(MainTabView(store: Store(initialState: .init()) { MainTabCoordinator() }))
      ),
      frame(
        4,
        "클래스 인트로",
        "intro",
        "real Class tab; intro hides tab bar",
        AnyView(MainTabView(store: Store(initialState: .init(selectedTab: MainTabCoordinator.Tab.classroom.rawValue)) {
          MainTabCoordinator()
            .dependency(\.classUseCase, previewRepository)
            .dependency(\.classMockRepository, previewRepository)
        }))
      ),
      frame(
        5,
        "시작 방식",
        "start-method",
        "existing content initially selected",
        AnyView(ClassStartMethodView(store: Store(initialState: .init()) { ClassStartMethodFeature() }))
      ),
      frame(
        6,
        "주제와 조건",
        "topic",
        "Figma category selection: philosophy",
        AnyView(ClassTopicView(store: Store(initialState: topic) { ClassTopicFeature() }))
      ),
      frame(
        7,
        "클래스 공유",
        "share",
        "owner mock room",
        AnyView(ClassShareView(store: Store(initialState: .init(room: owner)) { ClassShareFeature() }))
      ),
      frame(
        8,
        "기존 배틀 설정",
        "existing-setting",
        "first mock battle",
        AnyView(ClassSettingView(store: Store(initialState: .init(battle: ClassBattleSummary.mocks[0])) {
          ClassSettingFeature()
        }))
      ),
      frame(
        9,
        "기존 배틀 추천",
        "existing-recommend",
        "selected first mock battle",
        AnyView(ClassRecommendView(store: Store(initialState: existingRecommend) { ClassRecommendFeature() }))
      ),
      frame(
        10,
        "이름 입력",
        "join-name",
        "member room preview",
        AnyView(ClassJoinView(store: Store(initialState: .init(mode: .nickname, preview: member)) { ClassJoinFeature()
        }))
      ),
      frame(
        11,
        "코드 입력",
        "join-code",
        "empty code",
        AnyView(ClassJoinView(store: Store(initialState: .init(mode: .code)) { ClassJoinFeature() }))
      ),
      frame(
        12,
        "멤버 내 클래스",
        "member-classes",
        "Figma fixture: two open and one closed member room",
        classTab(.myClasses(memberList))
      ),
      frame(
        13,
        "멤버 클래스 상세",
        "member-detail",
        "open member room",
        classTab(.detail(.init(room: member)))
      ),
      frame(
        14,
        "멤버 목록",
        "member-list",
        "Figma participant member avatar fixture",
        classTab(.members(.init(
          room: member,
          members: MockClassRepository.figmaParticipantMembers,
          currentMemberID: 2,
          instanceID: UUID(),
          preloadedViewState: .loaded
        )))
      ),
      chatFrame(15, "댓글", "comment", .init(commentBattleId: battleID), session: session, battleID: battleID),
      chatFrame(
        16,
        "최종 투표",
        "final-vote",
        .init(route: .finalVote(battleId: battleID)),
        session: session,
        battleID: battleID
      ),
      chatFrame(17, "청취와 대화", "chat-room", chatRoom, session: session, battleID: battleID),
      chatFrame(
        18,
        "사전 투표",
        "pre-vote",
        .init(battleId: preVoteBattleID),
        session: preVoteSession,
        battleID: preVoteBattleID
      ),
      loadedClassFrame(
        19,
        "멤버 개인 리포트",
        "member-report",
        "member room summary tab",
        .report(.init(room: member, instanceID: UUID()))
      ),
      frame(
        20,
        "마감 배틀",
        "closed-battle",
        "closed member room",
        AnyView(ClassClosedBattleView(store: Store(initialState: .init(room: .mockClosedSociety)) {
          ClassClosedBattleFeature()
        }))
      ),
      frame(
        21,
        "운영자 내 클래스",
        "owner-classes",
        "three owner mock rooms",
        classTab(.myClasses(ownerList))
      ),
      frame(
        22,
        "운영자 클래스 상세",
        "owner-detail",
        "open owner room",
        classTab(.detail(.init(room: owner)))
      ),
      loadedClassFrame(
        23,
        "운영자 클래스 요약",
        "owner-dashboard",
        "loaded home metrics",
        .ownerDashboard(.init(room: owner, instanceID: UUID()))
      ),
      frame(
        24,
        "운영자 멤버 목록",
        "owner-members",
        "owner room with mock members",
        classTab(.members(.init(
          room: owner,
          members: ownerMembers,
          currentMemberID: 1,
          instanceID: UUID(),
          preloadedViewState: .loaded
        )))
      ),
      loadedClassFrame(
        25,
        "운영자 내 리포트",
        "owner-report",
        "loaded report metrics",
        .ownerDashboard(ownerReport)
      ),
      frame(
        26,
        "최종 투표 안내",
        "final-vote-alert",
        "AI chat completed; final vote confirmation",
        AnyView(ClassAIChatView(store: Store(initialState: aiChatAlert) {
          ClassAIChatFeature().dependency(\.classAIChatUseCase, MockClassAIChatUseCase())
        }))
      ),
      frame(
        27,
        "AI 질문 대화",
        "ai-chat",
        "round one before Foundation Models response",
        AnyView(ClassAIChatView(store: Store(initialState: .init(
          room: aiRoom,
          battleID: -1_000_801,
          selectedOptionID: 1
        )) { ClassAIChatFeature().dependency(\.classAIChatUseCase, MockClassAIChatUseCase()) }))
      ),
      frame(
        28,
        "AI 질문 단일 투표",
        "ai-vote",
        "AI question mock room",
        AnyView(ClassAIVoteView(store: Store(initialState: .init(
          room: aiRoom,
          battleID: -1_000_801,
          instanceID: UUID()
        )) {
          ClassAIVoteFeature()
        }))
      ),
    ]
  }
}

private struct VoteCaptureBattleUseCase: BattleInterface {
  let fetchCalls = LockIsolated((count: 0, battleID: Int?.none))
  let fetch: @Sendable (Int) async throws -> BattleDetail
  private let fallback = MockBattleRepository()

  func fetchBattle(battleId: Int) async throws -> BattleDetail {
    fetchCalls.withValue { $0 = (count: $0.count + 1, battleID: battleId) }
    return try await fetch(battleId)
  }

  func fetchTodayBattles() async throws -> TodayBattlePage {
    try await fallback.fetchTodayBattles()
  }

  func submitPreVote(
    battleId: Int,
    optionId: Int
  ) async throws -> PreVoteResult {
    try await fallback.submitPreVote(battleId: battleId, optionId: optionId)
  }

  func submitPostVote(
    battleId: Int,
    optionId: Int
  ) async throws -> PreVoteResult {
    try await fallback.submitPostVote(battleId: battleId, optionId: optionId)
  }

  func fetchScenario(battleId: Int) async throws -> BattleScenario {
    try await fallback.fetchScenario(battleId: battleId)
  }

  func fetchVoteStats(battleId: Int) async throws -> BattleVoteStats {
    try await fallback.fetchVoteStats(battleId: battleId)
  }

  func fetchPerspectives(
    battleId: Int,
    cursor: String?,
    size: Int?,
    optionId: Int?,
    sort: BattlePerspectiveSort?
  ) async throws -> BattlePerspectivePage {
    try await fallback.fetchPerspectives(
      battleId: battleId,
      cursor: cursor,
      size: size,
      optionId: optionId,
      sort: sort
    )
  }

  func createPerspective(
    battleId: Int,
    content: String,
    optionId: Int?
  ) async throws -> BattlePerspective? {
    try await fallback.createPerspective(battleId: battleId, content: content, optionId: optionId)
  }

  func fetchMyPerspective(battleId: Int) async throws -> BattlePerspective? {
    try await fallback.fetchMyPerspective(battleId: battleId)
  }

  func fetchRecommendedBattles(battleId: Int) async throws -> RecommendedBattlePage {
    try await fallback.fetchRecommendedBattles(battleId: battleId)
  }

  func proposeBattle(_ draft: BattleProposalDraft) async throws -> BattleProposal {
    try await fallback.proposeBattle(draft)
  }
}
