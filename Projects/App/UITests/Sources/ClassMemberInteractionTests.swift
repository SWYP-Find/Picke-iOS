//
//  ClassMemberInteractionTests.swift
//  PickeClassUITests
//
//  Created by Picke on 10/16/26.
//

import Foundation
import XCTest

@MainActor
final class ClassMemberInteractionTests: XCTestCase {
  private struct AuditState: Decodable {
    let scenario: String
    let route: String
    let listRoomIDs: [Int]
    let listTargetCount: Int
    let visibleMemberIDs: [Int]
    let persistedRoomIDs: [Int]
    let persistedMemberIDs: [Int]
    let persistedTargetCount: Int
    let currentMemberID: Int
    let snapshotKey: String
    let routeSnapshotKey: String
    let status: String
    let error: String
  }

  private let targetTitle = "회원 검증 대상 클래스"
  private let survivorTitle = "회원 검증 유지 클래스"

  override func setUpWithError() throws {
    continueAfterFailure = false
  }

  func testOwnerNameSheetRejectsWhitespaceAndPersistsAfterReentry() throws {
    let app = launch(scenario: "owner-remove")
    waitUntil("owner fixture ready") {
      self.audit(in: app)?.status == "ready" && self.audit(in: app)?.route == "list"
    }
    try targetCard(in: app).tap()
    waitUntil("class detail opened") { self.audit(in: app)?.route == "detail" }
    uniqueButton(beginning: "클래스 멤버", in: app).tap()
    waitForLoadedMembers(in: app)

    let search = app.textFields.matching(NSPredicate(
      format: "placeholderValue == %@", "이름을 입력해주세요."
    ))
    XCTAssertEqual(search.count, 1)
    let initialSearchValue = search.firstMatch.value as? String
    uniqueButton(label: "내 이름 수정", in: app).tap()
    let nameFields = app.textFields.matching(NSPredicate(
      format: "placeholderValue == %@", "이름을 입력해주세요"
    ))
    XCTAssertTrue(nameFields.firstMatch.waitForExistence(timeout: 5))
    XCTAssertEqual(nameFields.count, 1)
    let nameField = nameFields.firstMatch
    XCTAssertEqual(nameField.value as? String, "김선생")
    let save = uniqueButton(label: "수정하기", in: app)
    waitUntil("prefilled name can be saved") { save.isEnabled && save.isHittable }
    attach(app, name: "member-name-prefilled")

    clearNameField(nameField)
    nameField.typeText(" ")
    waitUntil("whitespace cannot be saved") {
      nameFields.count == 1 && nameField.value as? String == " " && !save.isEnabled
    }
    XCTAssertEqual(search.firstMatch.value as? String, initialSearchValue)
    attach(app, name: "member-name-whitespace-disabled")

    clearNameField(nameField)
    nameField.typeText("검증이름")
    waitUntil("valid replacement can be saved") {
      nameField.value as? String == "검증이름" && save.isEnabled && save.isHittable
    }
    save.tap()
    waitUntil("saved name is rendered and sheet is dismissed") {
      nameFields.count == 0 && app.staticTexts["검증이름"].exists
        && !app.staticTexts["김선생"].exists
    }
    XCTAssertEqual(search.firstMatch.value as? String, initialSearchValue)
    attach(app, name: "member-name-saved")

    try tapDiscoveredBack(in: app, title: "클래스 멤버")
    waitUntil("returned to class detail") { self.audit(in: app)?.route == "detail" }
    uniqueButton(beginning: "클래스 멤버", in: app).tap()
    waitForLoadedMembers(in: app)
    XCTAssertTrue(app.staticTexts["검증이름"].exists)
    XCTAssertFalse(app.staticTexts["김선생"].exists)
    uniqueButton(label: "내 이름 수정", in: app).tap()
    waitUntil("repository name is prefilled after reentry") {
      nameFields.count == 1 && nameFields.firstMatch.value as? String == "검증이름"
        && save.isEnabled && save.isHittable
    }
    attach(app, name: "member-name-reentered")
  }

  func testOwnerRemovesMemberAndUpdatedCountSurvivesBackNavigation() throws {
    let app = launch(scenario: "owner-remove")
    waitUntil("owner fixture ready") {
      guard let state = self.audit(in: app) else { return false }
      return state.status == "ready" && state.route == "list"
        && state.listRoomIDs == [1] && state.persistedRoomIDs == [1]
        && state.currentMemberID == 1 && state.persistedMemberIDs.contains(2)
    }
    let before = try requireAudit(in: app)
    XCTAssertEqual(before.listTargetCount, before.persistedTargetCount)
    attach(app, name: "owner-list-before")

    try targetCard(in: app).tap()
    waitUntil("class detail opened from card") { self.audit(in: app)?.route == "detail" }
    attach(app, name: "owner-detail-before")
    uniqueButton(beginning: "클래스 멤버", in: app).tap()
    waitUntil("members loaded") {
      guard let state = self.audit(in: app) else { return false }
      return state.status == "ready" && state.route == "members"
        && state.visibleMemberIDs.contains(2)
        && state.persistedMemberIDs.contains(2)
    }
    waitUntil("loaded members replace every skeleton row") {
      guard let state = self.audit(in: app) else { return false }
      let removeButtons = app.buttons.matching(NSPredicate(format: "label ENDSWITH %@", " 내보내기"))
      return state.visibleMemberIDs.count == 10
        && removeButtons.count == state.visibleMemberIDs.count - 1
        && app.buttons["공은지 내보내기"].isHittable
        && !app.descendants(matching: .any)["skeleton_root"].exists
    }
    attach(app, name: "owner-members-before")

    uniqueButton(label: "공은지 내보내기", in: app).tap()
    let confirm = uniqueButton(label: "내보내기", in: app)
    XCTAssertTrue(confirm.waitForExistence(timeout: 5), app.debugDescription)
    attach(app, name: "owner-remove-confirmation")
    confirm.tap()
    waitUntil("member removed in screen and repository") {
      guard let state = self.audit(in: app) else { return false }
      return state.status == "ready" && state.route == "members"
        && !state.visibleMemberIDs.contains(2)
        && !state.persistedMemberIDs.contains(2)
        && state.visibleMemberIDs.contains(3)
        && state.persistedMemberIDs.contains(3)
        && state.listTargetCount == before.listTargetCount - 1
        && state.persistedTargetCount == before.persistedTargetCount - 1
    }
    XCTAssertFalse(app.buttons["공은지 내보내기"].exists)
    attach(app, name: "owner-members-after")

    try tapDiscoveredBack(in: app, title: "클래스 멤버")
    waitUntil("back on updated detail") {
      guard let state = self.audit(in: app) else { return false }
      return state.route == "detail" && state.listTargetCount == before.listTargetCount - 1
    }
    attach(app, name: "owner-detail-after-back")
    try tapDiscoveredBack(in: app, title: "클래스 상세")
    waitUntil("updated list after back") {
      guard let state = self.audit(in: app) else { return false }
      return state.status == "ready" && state.route == "list"
        && state.listTargetCount == before.listTargetCount - 1
        && state.persistedTargetCount == before.persistedTargetCount - 1
        && !state.persistedMemberIDs.contains(2)
    }
    attach(app, name: "owner-list-after-back")
  }

  func testMemberLeavesTargetClassThroughCardManagement() throws {
    let app = launch(scenario: "member-leave")
    waitUntil("member fixture ready") {
      guard let state = self.audit(in: app) else { return false }
      return state.status == "ready" && state.route == "list"
        && state.listRoomIDs == [1, 2] && state.persistedRoomIDs == [1, 2]
        && state.currentMemberID == 2 && state.persistedMemberIDs.contains(2)
    }
    attach(app, name: "member-list-before")
    let card = try targetCard(in: app)
    let management = try scopedManagementButton(in: card, app: app)
    let tree = XCTAttachment(string: app.debugDescription)
    tree.name = "AX tree before card management"
    tree.lifetime = .keepAlways
    add(tree)
    management.tap()
    let leave = uniqueButton(beginning: "클래스 나가기", in: app)
    XCTAssertTrue(leave.waitForExistence(timeout: 5), app.debugDescription)
    attach(app, name: "member-management-sheet")
    leave.tap()
    let confirm = uniqueButton(label: "나가기", in: app)
    XCTAssertTrue(confirm.waitForExistence(timeout: 5), app.debugDescription)
    attach(app, name: "member-leave-confirmation")
    confirm.tap()
    waitUntil("target removed, survivor retained, repository updated") {
      guard let state = self.audit(in: app) else { return false }
      return state.status == "ready" && state.route == "list"
        && state.listRoomIDs == [2] && state.persistedRoomIDs == [2]
        && state.currentMemberID == -1
        && !state.persistedMemberIDs.contains(2)
        && state.persistedMemberIDs.contains(1)
        && !app.buttons.matching(NSPredicate(format: "label CONTAINS %@", self.targetTitle)).firstMatch.exists
        && app.buttons.matching(NSPredicate(format: "label CONTAINS %@", self.survivorTitle)).firstMatch.exists
        && !confirm.exists
    }
    attach(app, name: "member-list-after")
  }
}

@MainActor
private extension ClassMemberInteractionTests {
  func waitForLoadedMembers(in app: XCUIApplication) {
    waitUntil("ten member rows loaded without skeletons") {
      guard let state = self.audit(in: app) else { return false }
      return state.status == "ready" && state.route == "members"
        && state.visibleMemberIDs.count == 10
        && app.buttons["공은지 내보내기"].isHittable
        && !app.descendants(matching: .any)["skeleton_root"].exists
    }
  }

  func clearNameField(_ field: XCUIElement) {
    field.tap()
    let current = field.value as? String ?? ""
    field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count))
    waitUntil("name input cleared") {
      let value = field.value as? String
      return value == "" || value == "이름을 입력해주세요"
    }
  }

  func launch(scenario: String) -> XCUIApplication {
    let app = XCUIApplication(bundleIdentifier: "com.picke.class-audit")
    app.launchEnvironment["PICKE_MEMBER_SCENARIO"] = scenario
    app.launch()
    XCTAssertTrue(app.staticTexts["audit-member-state"].waitForExistence(timeout: 10), app.debugDescription)
    return app
  }

  private func audit(in app: XCUIApplication) -> AuditState? {
    guard let value = app.staticTexts["audit-member-state"].value as? String,
          let data = value.data(using: .utf8) else { return nil }
    return try? JSONDecoder().decode(AuditState.self, from: data)
  }

  private func requireAudit(in app: XCUIApplication) throws -> AuditState {
    try XCTUnwrap(audit(in: app), app.debugDescription)
  }

  func targetCard(in app: XCUIApplication) throws -> XCUIElement {
    let matches = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", targetTitle))
      .allElementsBoundByIndex.filter(\.isHittable)
    XCTAssertEqual(matches.count, 1, "Expected one target card: \(app.debugDescription)")
    return try XCTUnwrap(matches.first)
  }

  func scopedManagementButton(
    in card: XCUIElement,
    app: XCUIApplication
  ) throws -> XCUIElement {
    let matches = app.buttons.matching(NSPredicate(format: "label == %@", "클래스 관리"))
      .allElementsBoundByIndex.filter { $0.isHittable && card.frame.contains($0.frame) }
    XCTAssertEqual(matches.count, 1, "Expected one management button inside target card: \(app.debugDescription)")
    return try XCTUnwrap(matches.first)
  }

  func uniqueButton(
    label: String,
    in app: XCUIApplication
  ) -> XCUIElement {
    uniqueButton(matching: NSPredicate(format: "label == %@", label), in: app)
  }

  func uniqueButton(
    beginning prefix: String,
    in app: XCUIApplication
  ) -> XCUIElement {
    uniqueButton(matching: NSPredicate(format: "label BEGINSWITH %@", prefix), in: app)
  }

  func uniqueButton(
    matching predicate: NSPredicate,
    in app: XCUIApplication
  ) -> XCUIElement {
    let query = app.buttons.matching(predicate)
    let first = query.firstMatch
    XCTAssertTrue(first.waitForExistence(timeout: 5), app.debugDescription)
    let matches = query.allElementsBoundByIndex.filter(\.isHittable)
    XCTAssertEqual(matches.count, 1, "Button is missing or ambiguous: \(app.debugDescription)")
    return matches.first ?? first
  }

  func tapDiscoveredBack(
    in app: XCUIApplication,
    title: String
  ) throws {
    let tree = XCTAttachment(string: app.debugDescription)
    tree.name = "AX tree before back from \(title)"
    tree.lifetime = .keepAlways
    add(tree)
    let headings = app.staticTexts.matching(NSPredicate(format: "label == %@", title))
      .allElementsBoundByIndex.filter(\.isHittable)
    XCTAssertEqual(headings.count, 1, "Navigation title must be unique: \(app.debugDescription)")
    _ = try XCTUnwrap(headings.first)
    let candidates = app.buttons.matching(NSPredicate(
      format: "identifier == %@ AND label == %@",
      "chevron.left",
      "뒤로"
    )).allElementsBoundByIndex.filter(\.isHittable)
    XCTAssertEqual(candidates.count, 1, "Back control is ambiguous in captured AX tree")
    try XCTUnwrap(candidates.first).tap()
  }

  func waitUntil(
    _ description: String,
    condition: @escaping () -> Bool
  ) {
    let expectation = XCTNSPredicateExpectation(
      predicate: NSPredicate { _, _ in condition() },
      object: nil
    )
    XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: 10), .completed, description)
  }

  func attach(
    _ app: XCUIApplication,
    name: String
  ) {
    let attachment = XCTAttachment(screenshot: app.screenshot())
    attachment.name = name
    attachment.lifetime = .keepAlways
    add(attachment)
  }
}
