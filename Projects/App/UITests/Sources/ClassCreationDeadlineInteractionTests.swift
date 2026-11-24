//
//  ClassCreationDeadlineInteractionTests.swift
//  PickeClassUITests
//
//  Created by Picke on 10/17/26.
//

import Foundation
import XCTest

@MainActor
final class ClassCreationDeadlineInteractionTests: XCTestCase {
  private enum Column: String {
    case date = "날짜"
    case hour = "시"
    case minute = "분"
  }

  private struct AuditState: Decodable {
    let scenario: String
    let routeCount: Int
    let routeKind: String
    let isPush: Bool
    let hasDeadlineSelection: Bool
    let hasDeadlineEdit: Bool
    let selectionDraft: String
    let selectionSourceInstance: String
    let settingInstance: String
    let name: String
    let contentID: Int
    let contentKind: String
    let deadline: String
    let deadlineText: String
    let isDeadlineEnabled: Bool
    let requiresComment: Bool
    let ownerParticipates: Bool
  }

  private let initialDeadline = "2030-01-18T12:40"

  func testRegularCreationDeadlineConfirmReopenAndDiscard() throws {
    try verifyCreationDeadline(scenario: "regular")
  }

  func testAICreationDeadlineConfirmReopenAndDiscard() throws {
    try verifyCreationDeadline(scenario: "ai")
  }
}

@MainActor
private extension ClassCreationDeadlineInteractionTests {
  private func verifyCreationDeadline(scenario: String) throws {
    let app = XCUIApplication(bundleIdentifier: "com.picke.class-audit")
    app.launchEnvironment["PICKE_CREATION_DEADLINE_SCENARIO"] = scenario
    app.launch()
    XCTAssertTrue(auditElement(in: app).waitForExistence(timeout: 10))
    let initial = try requireAudit(in: app)
    assertSetting(initial, matches: initial, scenario: scenario, deadline: initialDeadline)
    XCTAssertEqual(initial.settingInstance, "00000000-0000-0000-0000-000000000123")
    // Independent fixture expectations: ClassRoom.mockJoinable.battle / ClassAIQuestion.examples[0].
    XCTAssertEqual(initial.contentID, scenario == "ai" ? 1 : 101)
    XCTAssertFalse(initial.hasDeadlineSelection)
    XCTAssertFalse(initial.hasDeadlineEdit)
    XCTAssertTrue(dateButton(in: app, label: initial.deadlineText).waitForExistence(timeout: 10))
    attach(app, name: "\(scenario)-initial-setting")

    dateButton(in: app, label: initial.deadlineText).tap()
    waitUntil("creation deadline panel opens") {
      guard let audit = self.audit(in: app) else { return false }
      return audit.hasDeadlineSelection && audit.selectionDraft == self.initialDeadline
        && audit.selectionSourceInstance == initial.settingInstance
        && self.confirmButton(in: app).exists
    }
    let confirmFrame = confirmButton(in: app).frame
    XCTAssertEqual(confirmFrame.height, 52, accuracy: 1)
    XCTAssertTrue(confirmButton(in: app).isEnabled)
    try assertOpenSelection(in: app, initial: initial, expected: initialDeadline, frame: confirmFrame)
    attach(app, name: "\(scenario)-initial-panel")

    for column in [Column.date, .hour, .minute] {
      let previous = try visibleValues(in: app)
      drag(column, in: app)
      waitForSettledSelection(in: app, initial: initial, frame: confirmFrame) { values in
        values[column] != previous[column]
      }
      XCTAssertNotEqual(try visibleValues(in: app)[column], previous[column])
      let selected = try canonicalDate(from: visibleValues(in: app))
      try assertOpenSelection(in: app, initial: initial, expected: selected, frame: confirmFrame)
      attach(app, name: "\(scenario)-\(column.rawValue)-settled")
    }

    let selected = try canonicalDate(from: visibleValues(in: app))
    XCTAssertNotEqual(selected, initialDeadline)
    XCTAssertTrue(confirmButton(in: app).isEnabled)
    attach(app, name: "\(scenario)-before-confirm")
    confirmButton(in: app).tap()
    waitUntil("confirmed selection appears in setting field") {
      guard let audit = self.audit(in: app) else { return false }
      return !audit.hasDeadlineSelection && audit.deadline == selected
        && self.dateButton(in: app, label: audit.deadlineText).exists
    }
    let confirmed = try requireAudit(in: app)
    assertSetting(confirmed, matches: initial, scenario: scenario, deadline: selected)
    XCTAssertFalse(confirmed.hasDeadlineSelection)
    XCTAssertFalse(confirmButton(in: app).exists)
    attach(app, name: "\(scenario)-confirmed-setting")

    dateButton(in: app, label: confirmed.deadlineText).tap()
    waitUntil("saved selection restores on reopen") {
      guard let audit = self.audit(in: app) else { return false }
      return audit.hasDeadlineSelection && audit.selectionDraft == selected
        && self.visibleCanonicalDate(in: app) == selected
        && self.confirmButton(in: app).isEnabled
    }
    try assertOpenSelection(in: app, initial: initial, expected: selected, frame: confirmFrame, savedDeadline: selected)
    attach(app, name: "\(scenario)-reopened-saved")

    let previousMinute = try visibleValues(in: app)[.minute]
    drag(.minute, in: app)
    waitForSettledSelection(in: app, initial: initial, frame: confirmFrame) { values in
      values[.minute] != previousMinute
    }
    let unconfirmed = try canonicalDate(from: visibleValues(in: app))
    XCTAssertNotEqual(unconfirmed, selected)
    try assertOpenSelection(in: app, initial: initial, expected: unconfirmed, frame: confirmFrame, savedDeadline: selected)
    attach(app, name: "\(scenario)-unconfirmed-change")

    tapDimAbovePanel(in: app)
    waitUntil("dim dismissal discards unconfirmed draft") {
      guard let audit = self.audit(in: app) else { return false }
      return !audit.hasDeadlineSelection && audit.deadline == selected
        && self.dateButton(in: app, label: audit.deadlineText).exists
    }
    let dismissed = try requireAudit(in: app)
    assertSetting(dismissed, matches: initial, scenario: scenario, deadline: selected)
    attach(app, name: "\(scenario)-dim-dismissed")

    dateButton(in: app, label: dismissed.deadlineText).tap()
    waitUntil("saved selection survives dim dismissal") {
      guard let audit = self.audit(in: app) else { return false }
      return audit.hasDeadlineSelection && audit.selectionDraft == selected
        && self.visibleCanonicalDate(in: app) == selected
        && self.confirmButton(in: app).isEnabled
    }
    try assertOpenSelection(in: app, initial: initial, expected: selected, frame: confirmFrame, savedDeadline: selected)
    attach(app, name: "\(scenario)-reopened-after-dismiss")
  }

  private func assertSetting(
    _ actual: AuditState,
    matches initial: AuditState,
    scenario: String,
    deadline: String
  ) {
    XCTAssertEqual(actual.scenario, scenario)
    XCTAssertEqual(actual.routeCount, 2)
    XCTAssertEqual(actual.routeKind, "setting")
    XCTAssertTrue(actual.isPush)
    XCTAssertFalse(actual.hasDeadlineEdit)
    XCTAssertEqual(actual.settingInstance, initial.settingInstance)
    XCTAssertFalse(actual.settingInstance.isEmpty)
    XCTAssertEqual(actual.name, initial.name)
    XCTAssertEqual(actual.name, "마감일 상호작용 검증 클래스")
    XCTAssertEqual(actual.contentKind, scenario)
    XCTAssertEqual(actual.contentID, initial.contentID)
    XCTAssertNotEqual(actual.contentID, 0)
    XCTAssertTrue(actual.isDeadlineEnabled)
    XCTAssertTrue(actual.requiresComment)
    XCTAssertTrue(actual.ownerParticipates)
    XCTAssertEqual(actual.deadline, deadline)
    XCTAssertFalse(actual.deadlineText.isEmpty)
  }

  private func assertOpenSelection(
    in app: XCUIApplication,
    initial: AuditState,
    expected: String,
    frame: CGRect,
    savedDeadline: String = "2030-01-18T12:40"
  ) throws {
    let audit = try requireAudit(in: app)
    assertSetting(audit, matches: initial, scenario: initial.scenario, deadline: savedDeadline)
    XCTAssertTrue(audit.hasDeadlineSelection)
    XCTAssertEqual(audit.selectionSourceInstance, initial.settingInstance)
    XCTAssertEqual(audit.selectionDraft, expected)
    XCTAssertEqual(try canonicalDate(from: visibleValues(in: app)), expected)
    XCTAssertEqual(confirmButton(in: app).frame, frame)
    XCTAssertTrue(confirmButton(in: app).isEnabled)
  }

  private func dateButton(
    in app: XCUIApplication,
    label: String
  ) -> XCUIElement {
    app.buttons[label]
  }

  private func auditElement(in app: XCUIApplication) -> XCUIElement {
    app.staticTexts["audit-class-creation-deadline-state"]
  }

  private func confirmButton(in app: XCUIApplication) -> XCUIElement {
    app.buttons["class-deadline-confirm"]
  }

  private func wheel(
    _ column: Column,
    in app: XCUIApplication
  ) -> XCUIElement {
    app.descendants(matching: .any)
      .matching(identifier: "class-deadline-wheel-\(column.rawValue)")
      .firstMatch
  }

  private func drag(
    _ column: Column,
    in app: XCUIApplication
  ) {
    let element = wheel(column, in: app)
    XCTAssertTrue(element.waitForExistence(timeout: 5))
    let center = element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
    center.press(
      forDuration: 0.3,
      thenDragTo: center.withOffset(CGVector(dx: 0, dy: -32)),
      withVelocity: .slow,
      thenHoldForDuration: 0.2
    )
  }

  private func waitForSettledSelection(
    in app: XCUIApplication,
    initial: AuditState,
    frame: CGRect,
    where matches: @escaping ([Column: String]) -> Bool
  ) {
    waitUntil("settled creation deadline after drag") {
      guard let values = self.optionalVisibleValues(in: app),
            matches(values),
            let canonical = self.parsedCanonicalDate(from: values),
            let audit = self.audit(in: app) else { return false }
      let confirm = self.confirmButton(in: app)
      return audit.hasDeadlineSelection
        && audit.selectionSourceInstance == initial.settingInstance
        && audit.selectionDraft == canonical
        && confirm.frame == frame
        && confirm.isEnabled
    }
  }

  private func tapDimAbovePanel(in app: XCUIApplication) {
    let panelTop = wheel(.date, in: app).frame.minY - 46
    let screen = app.frame
    let point = CGPoint(x: screen.midX, y: (screen.minY + 80 + panelTop - 20) / 2)
    XCTAssertLessThan(point.y, panelTop)
    XCTAssertFalse(auditElement(in: app).frame.contains(point))
    app.coordinate(withNormalizedOffset: .zero)
      .withOffset(CGVector(dx: point.x - screen.minX, dy: point.y - screen.minY))
      .tap()
  }

  private func waitUntil(
    _ description: String,
    condition: @escaping () -> Bool
  ) {
    let expectation = XCTNSPredicateExpectation(
      predicate: NSPredicate { _, _ in condition() },
      object: nil
    )
    XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: 8), .completed, description)
  }

  private func optionalVisibleValues(in app: XCUIApplication) -> [Column: String]? {
    var values: [Column: String] = [:]
    for column in [Column.date, .hour, .minute] {
      let element = wheel(column, in: app)
      guard element.exists, let value = element.value as? String else { return nil }
      values[column] = value
    }
    return values
  }

  private func visibleValues(in app: XCUIApplication) throws -> [Column: String] {
    try XCTUnwrap(optionalVisibleValues(in: app), "Missing custom wheel accessibility value")
  }

  private func visibleCanonicalDate(in app: XCUIApplication) -> String? {
    guard let values = optionalVisibleValues(in: app) else { return nil }
    return parsedCanonicalDate(from: values)
  }

  private func canonicalDate(from values: [Column: String]) throws -> String {
    try XCTUnwrap(parsedCanonicalDate(from: values), "Unexpected wheel values: \(values)")
  }

  private func parsedCanonicalDate(from values: [Column: String]) -> String? {
    guard let label = values[.date],
          let expression = try? NSRegularExpression(pattern: #"^(\d{1,2})월\s*(\d{1,2})일"#),
          let hourLabel = values[.hour], let hour = Int(hourLabel),
          let minuteLabel = values[.minute], let minute = Int(minuteLabel) else { return nil }
    let range = NSRange(label.startIndex..<label.endIndex, in: label)
    guard let match = expression.firstMatch(in: label, range: range) else { return nil }
    func number(_ index: Int) -> Int? {
      guard let range = Range(match.range(at: index), in: label) else { return nil }
      return Int(label[range])
    }
    guard let month = number(1), let day = number(2),
          (0 ... 23).contains(hour), (0 ... 59).contains(minute) else { return nil }
    var calendar = Calendar(identifier: .gregorian)
    guard let timeZone = TimeZone(identifier: "Asia/Seoul") else { return nil }
    calendar.timeZone = timeZone
    let components = DateComponents(year: 2030, month: month, day: day, hour: hour, minute: minute)
    guard let date = calendar.date(from: components) else { return nil }
    let checked = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
    guard checked.year == 2030,
          checked.month == month,
          checked.day == day,
          checked.hour == hour,
          checked.minute == minute else { return nil }
    return String(format: "%04d-%02d-%02dT%02d:%02d", 2030, month, day, hour, minute)
  }

  private func audit(in app: XCUIApplication) -> AuditState? {
    guard let value = auditElement(in: app).value as? String,
          let data = value.data(using: .utf8) else { return nil }
    return try? JSONDecoder().decode(AuditState.self, from: data)
  }

  private func requireAudit(in app: XCUIApplication) throws -> AuditState {
    try XCTUnwrap(audit(in: app), "Missing creation audit JSON: \(auditElement(in: app).debugDescription)")
  }

  private func attach(
    _ app: XCUIApplication,
    name: String
  ) {
    let attachment = XCTAttachment(screenshot: app.screenshot())
    attachment.name = name
    attachment.lifetime = .keepAlways
    add(attachment)
  }
}
