//
//  ClassDeadlineInteractionTests.swift
//  PickeClassUITests
//
//  Created by Picke on 10/15/26.
//

import Foundation
import XCTest

@MainActor
final class ClassDeadlineInteractionTests: XCTestCase {
  private enum Column: String {
    case date = "날짜"
    case hour = "시"
    case minute = "분"
  }

  private enum DragDirection {
    case up
    case down

    var offset: CGFloat { self == .up ? -32 : 32 }
  }

  private struct AuditState: Decodable {
    let status: String
    let draft: String?
    let list: String?
    let persisted: String?
  }

  private let fixedNow = "2030-01-15T10:30"

  func testNormalScenarioChangesEveryColumnAndSavesVisibleSelection() throws {
    let initial = "2030-01-18T12:40"
    let app = try launch(scenario: "normal", initial: initial)
    let save = saveButton(in: app)
    let frame = save.frame

    for column in [Column.date, .hour, .minute] {
      let previous = try visibleValues(in: app)
      drag(column, .up, in: app)
      waitForSettledSelection(in: app, initial: initial, frame: frame) { values in
        values[column] != previous[column]
      }
      let values = try visibleValues(in: app)
      XCTAssertNotEqual(values[column], previous[column], "\(column.rawValue) must change after a real drag")
      try assertSelection(in: app, initial: initial, frame: frame)
      attach(app, name: "normal-\(column.rawValue)-settled")
    }

    try saveAndAssert(in: app, initial: initial, frame: frame)
  }

  func testMinimumBoundaryClampsHourAndMinuteAndSaves() throws {
    let initial = "2030-01-15T10:31"
    let app = try launch(scenario: "minimum", initial: initial)
    let frame = saveButton(in: app).frame

    drag(.hour, .down, in: app)
    waitForSettledSelection(in: app, initial: initial, frame: frame) { values in
      values[.hour] == "10" && values[.minute] == "30"
    }
    XCTAssertEqual(try canonicalDate(from: visibleValues(in: app)), fixedNow)
    try assertSelection(in: app, initial: initial, frame: frame)
    attach(app, name: "minimum-clamped-to-now")

    // First move away from the boundary so the next assertion requires a new value.
    drag(.minute, .up, in: app)
    waitForSettledSelection(in: app, initial: initial, frame: frame) { values in
      values[.hour] == "10" && values[.minute] == "31"
    }
    try assertSelection(in: app, initial: initial, frame: frame)
    drag(.minute, .down, in: app)
    waitForSettledSelection(in: app, initial: initial, frame: frame) { values in
      values[.hour] == "10" && values[.minute] == "30"
    }
    XCTAssertEqual(try canonicalDate(from: visibleValues(in: app)), fixedNow,
                   "The minute drag must return the selection to the minimum")
    try assertSelection(in: app, initial: initial, frame: frame)
    attach(app, name: "minimum-minute-return-to-boundary")

    try saveAndAssert(in: app, initial: initial, frame: frame)
  }

  func testCyclicHourAndMinuteWrapBothDirectionsThenSave() throws {
    let initial = "2030-01-18T23:59"
    let app = try launch(scenario: "cycle", initial: initial)
    let frame = saveButton(in: app).frame

    try dragAndExpect(.hour, .up, value: "0", in: app, initial: initial, frame: frame)
    try dragAndExpect(.hour, .down, value: "23", in: app, initial: initial, frame: frame)
    XCTAssertFalse(saveButton(in: app).isEnabled, "Returning to the original date must disable save")
    try dragAndExpect(.minute, .up, value: "00", in: app, initial: initial, frame: frame)
    try dragAndExpect(.minute, .down, value: "59", in: app, initial: initial, frame: frame)
    XCTAssertFalse(saveButton(in: app).isEnabled, "Returning to the original date must disable save")

    try dragAndExpect(.minute, .down, value: "58", in: app, initial: initial, frame: frame)
    try saveAndAssert(in: app, initial: initial, frame: frame)
  }
}

@MainActor
private extension ClassDeadlineInteractionTests {
  private func launch(
    scenario: String,
    initial: String
  ) throws -> XCUIApplication {
    let app = XCUIApplication(bundleIdentifier: "com.picke.class-audit")
    app.launchEnvironment["PICKE_DEADLINE_SCENARIO"] = scenario
    app.launch()
    let save = saveButton(in: app)
    XCTAssertTrue(save.waitForExistence(timeout: 10), "Deadline editor did not appear: \(app.debugDescription)")
    XCTAssertTrue(auditElement(in: app).waitForExistence(timeout: 10))
    waitUntil("initial deadline \(initial)") {
      self.audit(in: app)?.status == "editing"
        && self.audit(in: app)?.draft == initial
        && self.visibleCanonicalDate(in: app) == initial
    }
    XCTAssertEqual(try canonicalDate(from: visibleValues(in: app)), initial)
    XCTAssertEqual(try requireAudit(in: app).draft, initial)
    XCTAssertFalse(save.isEnabled, "The unchanged initial selection must not be savable")
    attach(app, name: "\(scenario)-initial")
    return app
  }

  private func wheel(
    _ column: Column,
    in app: XCUIApplication
  ) -> XCUIElement {
    app.descendants(matching: .any)
      .matching(identifier: "class-deadline-wheel-\(column.rawValue)")
      .firstMatch
  }

  private func saveButton(in app: XCUIApplication) -> XCUIElement {
    app.buttons["class-deadline-save"]
  }

  private func auditElement(in app: XCUIApplication) -> XCUIElement {
    app.staticTexts["audit-state"]
  }

  private func drag(
    _ column: Column,
    _ direction: DragDirection,
    in app: XCUIApplication
  ) {
    let element = wheel(column, in: app)
    XCTAssertTrue(element.waitForExistence(timeout: 5), "Missing custom \(column.rawValue) wheel")
    let center = element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
    let destination = center.withOffset(CGVector(dx: 0, dy: direction.offset))
    center.press(
      forDuration: 0.3,
      thenDragTo: destination,
      withVelocity: .slow,
      thenHoldForDuration: 0.2
    )
  }

  private func dragAndExpect(
    _ column: Column,
    _ direction: DragDirection,
    value: String,
    in app: XCUIApplication,
    initial: String,
    frame: CGRect
  ) throws {
    drag(column, direction, in: app)
    waitForSettledSelection(in: app, initial: initial, frame: frame) { $0[column] == value }
    let values = try visibleValues(in: app)
    XCTAssertEqual(values[column], value, "\(column.rawValue) did not wrap to \(value)")
    try assertSelection(in: app, initial: initial, frame: frame)
    attach(app, name: "cycle-\(column.rawValue)-\(value)-settled")
  }

  private func waitForSettledSelection(
    in app: XCUIApplication,
    initial: String,
    frame: CGRect,
    where matches: @escaping ([Column: String]) -> Bool
  ) {
    waitUntil("settled visible deadline after drag") {
      guard let values = self.optionalVisibleValues(in: app),
            matches(values),
            let canonical = self.visibleCanonicalDate(in: app),
            let audit = self.audit(in: app) else { return false }
      let save = self.saveButton(in: app)
      return audit.status == "editing"
        && audit.draft == canonical
        && save.frame == frame
        && save.isEnabled == (canonical != initial)
    }
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

  private func assertSelection(
    in app: XCUIApplication,
    initial: String,
    frame: CGRect
  ) throws {
    let expected = try canonicalDate(from: visibleValues(in: app))
    let audit = try requireAudit(in: app)
    let save = saveButton(in: app)
    XCTAssertEqual(audit.status, "editing")
    XCTAssertEqual(audit.draft, expected, "Reducer draft must match all three visible wheels")
    XCTAssertGreaterThanOrEqual(expected, fixedNow, "Selection must respect the fixed minimum")
    XCTAssertEqual(save.frame, frame, "Save button must remain in a fixed panel position")
    XCTAssertEqual(save.isEnabled, expected != initial)
  }

  private func saveAndAssert(
    in app: XCUIApplication,
    initial: String,
    frame: CGRect
  ) throws {
    try assertSelection(in: app, initial: initial, frame: frame)
    let expected = try canonicalDate(from: visibleValues(in: app))
    XCTAssertNotEqual(expected, initial, "The test must save a changed selection")
    attach(app, name: "selected-before-save")
    saveButton(in: app).tap()
    waitUntil("saved deadline in list and repository") {
      guard let audit = self.audit(in: app) else { return false }
      return audit.status == "saved"
        && audit.list == expected
        && audit.persisted == expected
        && !self.wheel(.date, in: app).exists
        && !self.saveButton(in: app).exists
    }
    let audit = try requireAudit(in: app)
    XCTAssertEqual(audit.status, "saved")
    XCTAssertEqual(audit.list, expected, "Coordinator list must show the visible selection")
    XCTAssertEqual(audit.persisted, expected, "Repository must persist the visible selection")
    XCTAssertFalse(wheel(.date, in: app).exists, "Editor must be dismissed after save")
    XCTAssertFalse(saveButton(in: app).exists)
    attach(app, name: "saved-\(expected)")
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
    try XCTUnwrap(optionalVisibleValues(in: app), "Missing a custom wheel accessibility value")
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
          (0...23).contains(hour), (0...59).contains(minute) else { return nil }
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
    try XCTUnwrap(audit(in: app), "Missing or invalid audit-state JSON: \(auditElement(in: app).debugDescription)")
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
