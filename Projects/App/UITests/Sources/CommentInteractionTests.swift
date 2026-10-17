//
//  CommentInteractionTests.swift
//  PickeClassUITests
//
//  Created by Picke on 10/17/26.
//

import Foundation
import UIKit
import XCTest
import XCUIAutomation

@MainActor
final class CommentInteractionTests: XCTestCase {
  private let perspective = "첫 줄에는 나의 생각을 씁니다.\n둘째 줄에는 근거를 적습니다.\n셋째 줄에는 다른 관점을 봅니다.\n넷째 줄에는 질문을 남깁니다.\n다섯째 줄에서 결론을 맺습니다."
  private let reply = "답글 첫 줄을 적습니다.\n서로의 근거를 다시 살펴봅니다."

  override func setUpWithError() throws {
    continueAfterFailure = false
  }

  func testGlobalCommentReplyInputAndReentry() async throws {
    try await exercise(scenario: "global")
  }

  func testClassCommentReplyInputAndReentry() async throws {
    try await exercise(scenario: "class")
  }
}

private extension CommentInteractionTests {
  func exercise(scenario: String) async throws {
    let app = XCUIApplication(bundleIdentifier: "com.picke.class-audit")
    app.launchEnvironment["PICKE_COMMENT_SCENARIO"] = scenario
    app.launch()
    defer { app.terminate() }

    try await wait(in: app, for: "loaded comment root") {
      $0.scenario == scenario && $0.routeCount == 1 && $0.routeKind == "comment" && $0.isReady
    }
    if scenario == "class" {
      XCTAssertTrue(app.buttons["리포트"].exists, "Class comment root must show its report action")
    }
    let placeholder = scenario == "class" ? "내 생각을 입력해보세요" : "내용을 입력하세요"
    let emptyComposer = try composer(in: app, placeholder: placeholder, empty: true)
    let emptySend = try sendButton(in: app, scenario: scenario, composer: emptyComposer)
    XCTAssertFalse(emptySend.isEnabled, "Empty send must be disabled")
    if scenario == "global" {
      capture(in: app, name: "global-root-before-focus")
      try checkGlobalNavigation(in: app)
      try checkEmptyNotice(in: app, composer: emptyComposer, name: "global-root-before-focus")
    }

    emptyComposer.tap()
    try await waitForKeyboard(in: app, visible: true, name: scenario + "-root-keyboard")
    emptyComposer.typeText(perspective)
    try await wait(in: app, for: "complete five-line draft") {
      $0.commentText == self.perspective
    }
    let filledComposer = try composer(in: app, placeholder: placeholder, empty: false)
    XCTAssertEqual(filledComposer.value as? String, perspective)
    let filledSend = try sendButton(in: app, scenario: scenario, composer: filledComposer)
    XCTAssertTrue(filledSend.isEnabled && filledSend.isHittable)
    try await checkAboveKeyboard(
      composer: filledComposer,
      send: filledSend,
      in: app,
      name: scenario + "-root-keyboard"
    )
    capture(in: app, name: scenario + "-root-keyboard")
    if scenario == "global" {
      try checkEmptyNotice(in: app, composer: filledComposer, name: "global-root-keyboard")
    }
    filledSend.tap()

    try await wait(in: app, for: "posted full perspective") {
      $0.routeCount == 1 && $0.commentContents.contains(self.perspective) && $0.commentText.isEmpty
    }
    let postedComposer = try composer(in: app, placeholder: placeholder, empty: true)
    XCTAssertFalse(try sendButton(in: app, scenario: scenario, composer: postedComposer).isEnabled)
    if scenario == "global" {
      try await waitForKeyboard(in: app, visible: false, name: scenario + "-root-posted")
    } else if visibleKeyboard(in: app) != nil {
      let send = try sendButton(in: app, scenario: scenario, composer: postedComposer)
      try await checkAboveKeyboard(
        composer: postedComposer,
        send: send,
        in: app,
        name: scenario + "-root-posted"
      )
    }
    capture(in: app, name: scenario + "-root-posted")

    let firstComment = try await commentBody(in: app)
    firstComment.tap()
    try await wait(in: app, for: "reply push with forwarded parent", stableSamples: 4) {
      $0.routeCount == 2 && $0.routeKind == "reply-push" && $0.isReady
        && $0.perspectiveID != nil && $0.parentContent == self.perspective
    }
    XCTAssertEqual(app.sheets.count, 0)
    if scenario == "class" {
      do {
        try await waitForKeyboard(in: app, visible: false, name: "class-root-focus-carried-across-push")
      } catch {
        capture(in: app, name: "class root focus carried across push")
        throw error
      }
    } else {
      try await waitForKeyboard(in: app, visible: false, name: scenario + "-reply-open")
    }
    capture(in: app, name: scenario + "-reply-open")

    let replyComposer = try composer(in: app, placeholder: "내용을 입력하세요", empty: true)
    XCTAssertFalse(try sendButton(in: app, scenario: "global", composer: replyComposer).isEnabled)
    replyComposer.tap()
    try await waitForKeyboard(in: app, visible: true, name: scenario + "-reply-keyboard")
    replyComposer.typeText(reply)
    try await wait(in: app, for: "complete reply draft") { $0.replyText == self.reply }
    let filledReplyComposer = try composer(in: app, placeholder: "내용을 입력하세요", empty: false)
    XCTAssertEqual(filledReplyComposer.value as? String, reply)
    let replySend = try sendButton(in: app, scenario: "global", composer: filledReplyComposer)
    XCTAssertTrue(replySend.isEnabled && replySend.isHittable)
    try await checkAboveKeyboard(
      composer: filledReplyComposer,
      send: replySend,
      in: app,
      name: scenario + "-reply-keyboard"
    )
    capture(in: app, name: scenario + "-reply-keyboard")
    replySend.tap()

    try await wait(in: app, for: "posted reply") {
      $0.routeCount == 2 && $0.replyContents.filter { $0 == self.reply }.count == 1
        && $0.replyText.isEmpty
    }
    let postedReplyComposer = try composer(in: app, placeholder: "내용을 입력하세요", empty: true)
    XCTAssertFalse(try sendButton(in: app, scenario: "global", composer: postedReplyComposer).isEnabled)
    try await waitForKeyboard(in: app, visible: false, name: scenario + "-reply-posted")
    capture(in: app, name: scenario + "-reply-posted")

    let back = try uniqueHittableBack(in: app)
    back.tap()
    try await wait(in: app, for: "reloaded comment root") {
      $0.routeCount == 1 && $0.routeKind == "comment" && $0.isReady
        && $0.commentContents.contains(self.perspective)
    }
    let reloadedComment = try await commentBody(in: app)
    reloadedComment.tap()
    try await wait(in: app, for: "persisted reply after reentry") {
      $0.routeCount == 2 && $0.routeKind == "reply-push" && $0.isReady
        && $0.parentContent == self.perspective
        && $0.replyContents.filter { $0 == self.reply }.count == 1
    }
    XCTAssertEqual(app.sheets.count, 0)
    capture(in: app, name: scenario + "-reply-reopened")
  }

  func composer(
    in app: XCUIApplication,
    placeholder: String,
    empty: Bool
  ) throws -> XCUIElement {
    let fields = app.textFields.allElementsBoundByIndex + app.textViews.allElementsBoundByIndex
    let candidates = fields.filter { field in
      guard field.exists, field.isHittable else { return false }
      if empty {
        return field.label == placeholder || (field.value as? String) == placeholder
      }
      return (field.value as? String) != placeholder
    }
    guard candidates.count == 1 else {
      capture(in: app, name: "composer-ambiguous-\(placeholder)")
      throw AuditError.ambiguousComposer
    }
    return candidates[0]
  }

  func sendButton(
    in app: XCUIApplication,
    scenario: String,
    composer: XCUIElement
  ) throws -> XCUIElement {
    if scenario != "class" {
      let buttons = app.buttons.matching(NSPredicate(format: "label == %@", "보내기"))
        .allElementsBoundByIndex.filter { $0.exists && $0.frame.width > 0 }
      guard buttons.count == 1, isNearComposer(buttons[0], composer: composer) else {
        capture(in: app, name: "send-ambiguous")
        attachText(
          geometryDescription(in: app, composer: composer, send: buttons.first),
          name: "send-ambiguous-geometry"
        )
        throw AuditError.ambiguousSend
      }
      return buttons[0]
    }
    let keyboardTop = visibleKeyboard(in: app)?.frame.minY ?? app.frame.maxY
    let buttons = app.buttons.allElementsBoundByIndex.filter { button in
      let frame = button.frame
      return button.exists && isNearComposer(button, composer: composer)
        && (CGFloat(24) ... CGFloat(60)).contains(frame.width)
        && (CGFloat(24) ... CGFloat(60)).contains(frame.height)
        && frame.maxY <= keyboardTop + 1
    }
    guard buttons.count == 1 else {
      capture(in: app, name: "class-send-ambiguous")
      attachText(
        geometryDescription(in: app, composer: composer, send: buttons.first),
        name: "class-send-ambiguous-geometry"
      )
      throw AuditError.ambiguousSend
    }
    attachText("class send label=\(buttons[0].label), frame=\(buttons[0].frame)", name: "class-send-discovery")
    return buttons[0]
  }

  func commentBody(in app: XCUIApplication) async throws -> XCUIElement {
    var stableSamples = 0
    var previousFrame: CGRect?
    for _ in 0 ..< 40 {
      if let state = try? readState(in: app),
         state.routeCount == 1, state.routeKind == "comment", state.isReady,
         state.commentContents.contains(perspective)
      {
        let matches = app.buttons.matching(NSPredicate(format: "label == %@", perspective))
          .allElementsBoundByIndex.filter(\.isHittable)
        let candidates = matches.isEmpty
          ? app.buttons.matching(NSPredicate(format: "label == %@", "자세히 보기"))
          .allElementsBoundByIndex.filter(\.isHittable)
          : matches
        if candidates.count == 1 {
          let button = candidates[0]
          let frame = button.frame
          stableSamples = previousFrame == frame ? stableSamples + 1 : 1
          previousFrame = frame
          if stableSamples >= 8 {
            attachText("stableSamples=\(stableSamples); frame=\(frame)", name: "comment-body-stable")
            return button
          }
        } else {
          stableSamples = 0
          previousFrame = nil
        }
      } else {
        stableSamples = 0
        previousFrame = nil
      }
      try await Task.sleep(for: .milliseconds(250))
    }
    capture(in: app, name: "comment-body-not-stable")
    throw AuditError.ambiguousComment
  }

  func uniqueHittableBack(in app: XCUIApplication) throws -> XCUIElement {
    let matches = app.buttons.matching(NSPredicate(format: "label == %@", "뒤로"))
      .allElementsBoundByIndex.filter(\.isHittable)
    guard matches.count == 1 else {
      capture(in: app, name: "back-ambiguous")
      throw AuditError.ambiguousBack
    }
    return matches[0]
  }

  func checkGlobalNavigation(in app: XCUIApplication) throws {
    let back = try uniqueHittableBack(in: app)
    let row = back.frame.minY ... back.frame.maxY
    let buttons = app.buttons.allElementsBoundByIndex.filter {
      $0.isHittable && row.contains($0.frame.midY)
    }
    attachText(
      buttons.map { "label=\($0.label); identifier=\($0.identifier); frame=\($0.frame)" }.joined(separator: "\n"),
      name: "global-navigation-buttons"
    )
    XCTAssertEqual(buttons.count, 1, "Figma 8661:8290 has only the back button in the navigation row")
    XCTAssertFalse(buttons.contains { $0.frame.midX > app.frame.midX }, "Navigation must have no trailing action")
    XCTAssertFalse(app.buttons["chevron.right"].exists, "The extra forward chevron must be absent")
  }

  func checkEmptyNotice(
    in app: XCUIApplication,
    composer: XCUIElement,
    name: String
  ) throws {
    let notices = app.staticTexts.matching(NSPredicate(format: "label == %@", "아직 작성된 관점이 없습니다"))
      .allElementsBoundByIndex
    let scrolls = app.scrollViews.containing(NSPredicate(format: "label == %@", "아직 작성된 관점이 없습니다"))
      .allElementsBoundByIndex
    attachText(
      "noticeFrames=\(notices.map(\.frame)); viewportFrames=\(scrolls.map(\.frame)); composer=\(composer.frame)",
      name: name + "-empty-notice-geometry"
    )
    guard notices.count == 1, scrolls.count == 1 else {
      capture(in: app, name: name + "-empty-notice-ambiguous")
      throw AuditError.ambiguousEmptyNotice
    }
    let notice = notices[0].frame
    let viewport = scrolls[0].frame
    XCTAssertGreaterThan(notice.width, 0)
    XCTAssertGreaterThan(notice.height, 0)
    XCTAssertGreaterThan(viewport.width, 0)
    XCTAssertGreaterThan(viewport.height, 0)
    XCTAssertGreaterThanOrEqual(notice.minY, viewport.minY - 0.5, "Empty notice must stay below the viewport top")
    XCTAssertLessThanOrEqual(notice.maxY, viewport.maxY + 0.5, "Empty notice must stay above the viewport bottom")
    XCTAssertLessThanOrEqual(notice.maxY, composer.frame.minY, "Empty notice must stay above the composer")
  }

  func checkAboveKeyboard(
    composer: XCUIElement,
    send: XCUIElement,
    in app: XCUIApplication,
    name: String
  ) async throws {
    for _ in 0 ..< 40 {
      if let keyboard = visibleKeyboard(in: app),
         composer.frame.maxY <= keyboard.frame.minY + 1,
         send.frame.maxY <= keyboard.frame.minY + 1
      {
        attachText(geometryDescription(in: app, composer: composer, send: send), name: name + "-geometry")
        return
      }
      try await Task.sleep(for: .milliseconds(250))
    }
    attachText(geometryDescription(in: app, composer: composer, send: send), name: name + "-geometry-failed")
    capture(in: app, name: name + "-geometry-failed")
    throw AuditError.geometryMismatch
  }

  func visibleKeyboard(in app: XCUIApplication) -> XCUIElement? {
    let appFrame = app.frame
    return app.keyboards.allElementsBoundByIndex.first { keyboard in
      let frame = keyboard.frame
      let intersection = frame.intersection(appFrame)
      return keyboard.exists && frame.minY < appFrame.maxY
        && !intersection.isNull && intersection.width > 0 && intersection.height > 0
    }
  }

  func isNearComposer(
    _ button: XCUIElement,
    composer: XCUIElement
  ) -> Bool {
    let frame = button.frame
    let field = composer.frame
    return frame.minX >= field.maxX - 1
      && frame.minX - field.maxX <= 60
      && frame.maxY >= field.minY && frame.minY <= field.maxY
  }

  func geometryDescription(
    in app: XCUIApplication,
    composer: XCUIElement,
    send: XCUIElement?
  ) -> String {
    let keyboards = app.keyboards.allElementsBoundByIndex.map {
      "frame=\($0.frame), hittable=\($0.isHittable)"
    }
    let sendDescription = send.map {
      "frame=\($0.frame), hittable=\($0.isHittable), enabled=\($0.isEnabled)"
    } ?? "none"
    return "app=\(app.frame); keyboards=\(keyboards); composer=\(composer.frame), hittable=\(composer.isHittable); send=\(sendDescription)"
  }

  func waitForKeyboard(
    in app: XCUIApplication,
    visible: Bool,
    name: String
  ) async throws {
    for _ in 0 ..< 40 {
      if (visibleKeyboard(in: app) != nil) == visible {
        return
      }
      try await Task.sleep(for: .milliseconds(250))
    }
    capture(in: app, name: name + "-keyboard-failed")
    let keyboards = app.keyboards.allElementsBoundByIndex.map {
      "frame=\($0.frame), hittable=\($0.isHittable)"
    }
    attachText(
      "app=\(app.frame); keyboards=\(keyboards)",
      name: name + "-keyboard-geometry-failed"
    )
    throw AuditError.keyboardMismatch
  }

  func wait(
    in app: XCUIApplication,
    for description: String,
    stableSamples: Int = 1,
    condition: (AuditState) -> Bool
  ) async throws {
    var matchedSamples = 0
    for _ in 0 ..< 40 {
      if let state = try? readState(in: app), condition(state) {
        matchedSamples += 1
        if matchedSamples >= stableSamples {
          return
        }
      } else {
        matchedSamples = 0
      }
      try await Task.sleep(for: .milliseconds(250))
    }
    capture(in: app, name: "state-failed-\(description)")
    throw AuditError.stateTimeout
  }

  func readState(in app: XCUIApplication) throws -> AuditState {
    let label = app.staticTexts["audit-comment-state"]
    guard label.exists, let value = label.value as? String,
          let data = value.data(using: .utf8)
    else { throw AuditError.missingState }
    return try JSONDecoder().decode(AuditState.self, from: data)
  }

  func capture(
    in app: XCUIApplication,
    name: String
  ) {
    let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
    screenshot.name = name
    screenshot.lifetime = .keepAlways
    add(screenshot)
    attachText(app.debugDescription, name: name + "-accessibility")
    if let label = app.staticTexts["audit-comment-state"].value as? String {
      attachText(label, name: name + "-state")
    }
  }

  func attachText(
    _ text: String,
    name: String
  ) {
    let attachment = XCTAttachment(string: text)
    attachment.name = name
    attachment.lifetime = .keepAlways
    add(attachment)
  }

  struct AuditState: Decodable {
    let scenario: String
    let routeCount: Int
    let routeKind: String
    let isReady: Bool
    let commentText: String
    let replyText: String
    let perspectiveID: Int?
    let parentContent: String
    let commentContents: [String]
    let replyContents: [String]
    let replyCount: Int
    let selectedFilter: String
  }

  enum AuditError: Error {
    case ambiguousComposer
    case ambiguousSend
    case ambiguousComment
    case ambiguousBack
    case ambiguousEmptyNotice
    case keyboardMismatch
    case geometryMismatch
    case missingState
    case stateTimeout
  }
}
