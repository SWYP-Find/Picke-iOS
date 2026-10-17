//
//  ClassJoinInteractionTests.swift
//  PickeClassUITests
//
//  Created by Picke on 10/17/26.
//

import Foundation
import UIKit
import XCTest
import XCUIAutomation

@MainActor
final class ClassJoinInteractionTests: XCTestCase {
  override func setUpWithError() throws {
    continueAfterFailure = false
  }

  func testParticipationUsesPushWithRealKeyboardInput() async throws {
    try await exercise(recoverFromErrors: false)
  }

  func testInvalidCodeAndDuplicateNameRecoverThroughInput() async throws {
    try await exercise(recoverFromErrors: true)
  }
}

private extension ClassJoinInteractionTests {
  func exercise(recoverFromErrors: Bool) async throws {
    let app = XCUIApplication(bundleIdentifier: "com.picke.class-audit")
    app.launchEnvironment["PICKE_CLASS_JOIN_INTERACTION"] = "1"
    app.launch()
    var completed = false
    defer {
      if !completed {
        capture(in: app, name: "join-flow-incomplete")
      }
      app.terminate()
    }

    try await wait(in: app, for: "intro") {
      $0.routeCount == 1 && $0.lastRouteKind == "intro"
    }
    try checkRoutes(in: app)
    capture(in: app, name: "join-intro")
    let cards = app.buttons.allElementsBoundByIndex.filter {
      $0.isHittable && ($0.label == "클래스 참여하기" || $0.staticTexts["클래스 참여하기"].exists)
    }
    guard cards.count == 1 else {
      capture(in: app, name: "join-intro-ambiguous")
      throw AuditError.ambiguousControl
    }
    cards[0].tap()

    try await wait(in: app, for: "code push") {
      $0.routeCount == 2 && $0.lastRouteKind == "join" && $0.lastMode == "code" && $0.isPush
    }
    try checkRoutes(in: app)
    _ = try await controls(in: app, mode: "code", enabled: false, keyboard: false)
    capture(in: app, name: "join-code-empty")
    if recoverFromErrors {
      let invalid = try await type("BAD123", in: app, mode: "code", replacing: false)
      invalid.tap()
      try await wait(in: app, for: "invalid code") {
        $0.routeCount == 2 && $0.lastMode == "code" && !$0.isLoading
          && $0.errorMessage == "참여 코드를 다시 확인해 주세요."
          && $0.nicknameErrorMessage == nil && $0.nicknameValidationMessage == nil
      }
      try checkRoutes(in: app)
      try await checkMessage("참여 코드를 다시 확인해 주세요.", in: app, name: "join-code-error")
    }
    let codeCTA = try await type("PK9T3S", in: app, mode: "code", replacing: recoverFromErrors)
    codeCTA.tap()

    try await wait(in: app, for: "nickname push") {
      $0.routeCount == 3 && $0.lastRouteKind == "join" && $0.lastMode == "nickname"
        && $0.isPush && $0.previewID == 4 && !$0.isLoading
    }
    try checkRoutes(in: app)
    attachText(
      "keyboardVisibleBeforeNicknameTap=\(visibleKeyboard(in: app) != nil)",
      name: "join-nickname-arrival-keyboard"
    )
    _ = try await controls(in: app, mode: "nickname", enabled: false, keyboard: false)
    capture(in: app, name: "join-nickname-arrival")
    if recoverFromErrors {
      let duplicate = try await type("운영자", in: app, mode: "nickname", replacing: false)
      duplicate.tap()
      try await wait(in: app, for: "duplicate nickname") {
        $0.routeCount == 3 && $0.lastMode == "nickname" && !$0.isLoading
          && $0.nicknameErrorMessage == "이미 사용 중인 이름이에요."
          && $0.nicknameValidationMessage == "이미 사용 중인 이름이에요."
          && $0.errorMessage == nil
      }
      try checkRoutes(in: app)
      try await checkMessage("이미 사용 중인 이름이에요.", in: app, name: "join-nickname-error")
    }
    let nicknameCTA = try await type("민지", in: app, mode: "nickname", replacing: recoverFromErrors)
    nicknameCTA.tap()

    try await wait(in: app, for: "joined detail push") {
      $0.routeCount == 2 && $0.lastRouteKind == "detail" && $0.isPush
        && $0.detailRoomID == 4 && $0.memberCount == 13 && $0.roomRole == "member"
        && $0.pendingJoinCleared && !$0.isLoading
    }
    try checkRoutes(in: app)
    try await checkMessage("사회 토론 수업", in: app, name: "join-completed-detail")
    completed = true
  }

  func type(
    _ text: String,
    in app: XCUIApplication,
    mode: String,
    replacing: Bool
  ) async throws -> XCUIElement {
    let field = try currentField(in: app, mode: mode)
    field.tap()
    try await waitForKeyboard(in: app)
    if replacing {
      let value = field.value as? String ?? ""
      let deleteCount = min(64, max(8, value.utf16.count * 4 + 8))
      attachText(
        "value=\(value); utf16Count=\(value.utf16.count); deleteCount=\(deleteCount)\n\(geometry(in: app))",
        name: "join-\(mode)-replacement"
      )
      field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: deleteCount))
      try await wait(in: app, for: mode + " cleared by keyboard") {
        (mode == "code" ? $0.code : $0.nickname).isEmpty
      }
      let cleared = try currentField(in: app, mode: mode)
      let clearedValue = cleared.value as? String ?? ""
      let placeholder = mode == "code" ? "" : "내용을 입력하세요"
      guard clearedValue.isEmpty || clearedValue == placeholder else {
        capture(in: app, name: "join-\(mode)-not-cleared")
        throw AuditError.inputMismatch
      }
    }
    try currentField(in: app, mode: mode).typeText(text)
    try await wait(in: app, for: mode + " exact draft") {
      (mode == "code" ? $0.code : $0.nickname) == text
        && $0.errorMessage == nil && $0.nicknameErrorMessage == nil
        && $0.nicknameValidationMessage == nil
    }
    let ready = try await controls(in: app, mode: mode, enabled: true, keyboard: true)
    XCTAssertEqual(ready.field.value as? String, text, "Actual field must contain the full typed draft")
    capture(in: app, name: "join-\(mode)-typed-\(text)")
    return ready.cta
  }

  func controls(
    in app: XCUIApplication,
    mode: String,
    enabled: Bool,
    keyboard: Bool
  ) async throws -> (field: XCUIElement, cta: XCUIElement) {
    var stable = 0
    var previous: [CGRect] = []
    for _ in 0 ..< 40 {
      if let field = try? currentField(in: app, mode: mode) {
        let candidates = app.buttons.matching(NSPredicate(format: "label == %@", "클래스 참여하기"))
          .allElementsBoundByIndex.filter {
            $0.exists && $0.isHittable && fullyVisible($0.frame, in: app.frame)
              && $0.frame.minY > field.frame.maxY
          }
        if candidates.count == 1, candidates[0].isEnabled == enabled {
          let cta = candidates[0]
          let keyboardFrame = visibleKeyboard(in: app)?.frame
          let avoidsKeyboard = keyboardFrame.map {
            field.frame.maxY <= $0.minY + 1 && cta.frame.maxY <= $0.minY + 1
          } ?? false
          if !keyboard || avoidsKeyboard {
            let frames = [field.frame, cta.frame, keyboardFrame ?? .zero]
            stable = frames == previous ? stable + 1 : 1
            previous = frames
            if stable >= 4 {
              attachText(geometry(in: app), name: "join-\(mode)-controls-enabled-\(enabled)")
              return (field, cta)
            }
          } else {
            stable = 0
          }
        } else {
          stable = 0
        }
      } else {
        stable = 0
      }
      try await Task.sleep(for: .milliseconds(250))
    }
    capture(in: app, name: "join-\(mode)-controls-failed")
    throw AuditError.geometryMismatch
  }

  func currentField(
    in app: XCUIApplication,
    mode: String
  ) throws -> XCUIElement {
    let label = mode == "code" ? "참여 코드, 6자리" : "클래스에서 사용할 이름"
    let fields = app.textFields.matching(NSPredicate(format: "label == %@", label))
      .allElementsBoundByIndex.filter { $0.exists && $0.isHittable && fullyVisible($0.frame, in: app.frame) }
    guard fields.count == 1 else { throw AuditError.ambiguousControl }
    return fields[0]
  }

  func checkRoutes(in app: XCUIApplication) throws {
    let state = try readState(in: app)
    attachText(
      state.routes.map { "\($0.kind): push=\($0.isPush), presented=\($0.isPresented)" }.joined(separator: "\n"),
      name: "join-route-styles"
    )
    XCTAssertEqual(state.routes.count, state.routeCount)
    XCTAssertEqual(state.routes.first?.kind, "intro")
    XCTAssertEqual(state.routes.first?.isPush, false)
    XCTAssertTrue(state.routes.dropFirst().allSatisfy(\.isPush))
    XCTAssertFalse(state.routes.contains(where: \.isPresented))
    XCTAssertFalse(state.hasDeadlineEdit || state.hasDeadlineSelection || state.hasDetailModal || state.hasDetailAlert)
    XCTAssertEqual(app.sheets.count, 0)
  }

  func checkMessage(
    _ message: String,
    in app: XCUIApplication,
    name: String
  ) async throws {
    for _ in 0 ..< 40 {
      let labels = app.staticTexts.matching(NSPredicate(format: "label == %@", message))
        .allElementsBoundByIndex.filter { $0.isHittable && fullyVisible($0.frame, in: app.frame) }
      if labels.count == 1 {
        capture(in: app, name: name)
        return
      }
      try await Task.sleep(for: .milliseconds(250))
    }
    capture(in: app, name: name + "-missing")
    throw AuditError.missingMessage
  }

  func wait(
    in app: XCUIApplication,
    for description: String,
    condition: (AuditState) -> Bool
  ) async throws {
    var stable = 0
    for _ in 0 ..< 40 {
      if let state = try? readState(in: app), condition(state) {
        stable += 1
        if stable >= 4 {
          return
        }
      } else {
        stable = 0
      }
      try await Task.sleep(for: .milliseconds(250))
    }
    capture(in: app, name: "join-state-failed-\(description)")
    throw AuditError.stateTimeout
  }

  func waitForKeyboard(in app: XCUIApplication) async throws {
    for _ in 0 ..< 40 {
      if visibleKeyboard(in: app) != nil {
        return
      }
      try await Task.sleep(for: .milliseconds(250))
    }
    capture(in: app, name: "join-keyboard-missing")
    throw AuditError.keyboardMismatch
  }

  func visibleKeyboard(in app: XCUIApplication) -> XCUIElement? {
    app.keyboards.allElementsBoundByIndex.first {
      let frame = $0.frame
      let intersection = frame.intersection(app.frame)
      return $0.exists && frame.width > 0 && frame.height > 0 && frame.minY < app.frame.maxY
        && !intersection.isNull && intersection.width > 0 && intersection.height > 0
    }
  }

  func fullyVisible(
    _ frame: CGRect,
    in viewport: CGRect
  ) -> Bool {
    frame.width > 0 && frame.height > 0 && viewport.insetBy(dx: -0.5, dy: -0.5).contains(frame)
  }

  func geometry(in app: XCUIApplication) -> String {
    let fields = app.textFields.allElementsBoundByIndex.map {
      "label=\($0.label), value=\(String(describing: $0.value)), frame=\($0.frame), hittable=\($0.isHittable)"
    }
    let ctas = app.buttons.allElementsBoundByIndex.map {
      "label=\($0.label), frame=\($0.frame), enabled=\($0.isEnabled), hittable=\($0.isHittable)"
    }
    let keyboards = app.keyboards.allElementsBoundByIndex.map { "frame=\($0.frame), hittable=\($0.isHittable)" }
    return "app=\(app.frame)\nfields=\(fields)\nbuttons=\(ctas)\nkeyboards=\(keyboards)"
  }

  func readState(in app: XCUIApplication) throws -> AuditState {
    let label = app.staticTexts["audit-class-join-state"]
    guard label.exists, let value = label.value as? String,
          let data = value.data(using: .utf8) else { throw AuditError.missingState }
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
    attachText(geometry(in: app), name: name + "-geometry")
    if let value = app.staticTexts["audit-class-join-state"].value as? String {
      attachText(value, name: name + "-state")
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
    let routeCount: Int
    let routes: [RouteState]
    let lastRouteKind: String
    let isPush: Bool
    let lastMode: String
    let code: String
    let nickname: String
    let previewID: Int?
    let detailRoomID: Int?
    let memberCount: Int
    let roomRole: String
    let isLoading: Bool
    let errorMessage: String?
    let nicknameErrorMessage: String?
    let nicknameValidationMessage: String?
    let hasDeadlineEdit: Bool
    let hasDeadlineSelection: Bool
    let hasDetailModal: Bool
    let hasDetailAlert: Bool
    let pendingJoinCleared: Bool
  }

  struct RouteState: Decodable {
    let kind: String
    let isPush: Bool
    let isPresented: Bool
  }

  enum AuditError: Error {
    case ambiguousControl
    case geometryMismatch
    case inputMismatch
    case missingMessage
    case keyboardMismatch
    case missingState
    case stateTimeout
  }
}
