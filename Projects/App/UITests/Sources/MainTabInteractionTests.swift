//
//  MainTabInteractionTests.swift
//  PickeClassUITests
//
//  Created by Picke on 10/17/26.
//

import Foundation
import XCTest

@MainActor
final class MainTabInteractionTests: XCTestCase {
  private var activeApp: XCUIApplication?

  private struct AuditState: Decodable {
    let mounted: Bool
    let fixtureFocused: Bool
    let selectedTab: Int
    let previousTab: Int
    let shouldHideTabBar: Bool
    let isKeyboardVisible: Bool
    let classRouteCount: Int
    let classRouteKind: String
    let memberInstanceID: String
    let memberCount: Int
    let memberSearch: String
    let reportInstanceID: String
    let reportShowsMyOpinions: Bool
  }

  override func setUpWithError() throws {
    continueAfterFailure = false
  }

  func testFiveTabButtonsPreserveMembersAndClassReselectResetsOnlyClass() throws {
    let app = launch(scenario: "members")
    waitUntil("owner members and custom bar mounted") {
      guard let state = self.audit(in: app) else { return false }
      return state.selectedTab == 4 && state.classRouteKind == "members"
        && state.memberCount == 22 && !state.shouldHideTabBar
    }
    let original = try XCTUnwrap(audit(in: app))
    assertVisibleTabBar(in: app, selected: 4)
    attach(app, name: "tabs-owner-members")

    let search = app.textFields["class-member-search"]
    XCTAssertTrue(search.waitForExistence(timeout: 5))
    search.tap()
    search.typeText("김")
    waitUntil("keyboard hides tabs") {
      self.audit(in: app)?.isKeyboardVisible == true
        && self.audit(in: app)?.shouldHideTabBar == true
        && self.noCustomTabs(in: app)
    }
    attach(app, name: "tabs-search-keyboard-hidden")
    app.buttons["내 이름 수정"].tap()
    waitUntil("name sheet hides tabs") {
      self.audit(in: app)?.shouldHideTabBar == true && self.noCustomTabs(in: app)
        && app.textFields["class-member-name"].exists
    }
    XCTAssertEqual(app.tabBars.count, 0)
    let name = app.textFields["class-member-name"]
    name.tap()
    XCTAssertGreaterThan(app.keyboards.count, 0)
    attach(app, name: "tabs-name-sheet-keyboard")
    let save = app.buttons["수정하기"]
    XCTAssertTrue(save.isEnabled)
    save.tap()
    waitUntil("name sheet closes and tabs return") {
      !name.exists && self.audit(in: app)?.isKeyboardVisible == false
        && self.audit(in: app)?.shouldHideTabBar == false
    }
    assertVisibleTabBar(in: app, selected: 4)
    XCTAssertEqual(try XCTUnwrap(audit(in: app)).memberInstanceID, original.memberInstanceID)
    XCTAssertEqual(try XCTUnwrap(audit(in: app)).memberSearch, "김")
    attach(app, name: "tabs-restored-after-name-sheet")

    for tab in [0, 1, 3, 4] {
      tabButton(tab, in: app).tap()
      waitUntil("tab \(tab) selected") {
        self.audit(in: app)?.selectedTab == tab
          && self.audit(in: app)?.shouldHideTabBar == false
      }
      assertVisibleTabBar(in: app, selected: tab)
    }
    XCTAssertEqual(try XCTUnwrap(audit(in: app)).memberInstanceID, original.memberInstanceID)
    XCTAssertEqual(try XCTUnwrap(audit(in: app)).memberSearch, "김")

    search.tap()
    search.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 1))
    waitUntil("search cleared") { self.audit(in: app)?.memberSearch.isEmpty == true }
    app.buttons["내 이름 수정"].tap()
    XCTAssertTrue(name.waitForExistence(timeout: 5))
    name.tap()
    app.buttons["수정하기"].tap()
    waitUntil("tabs return after clearing search") {
      self.audit(in: app)?.shouldHideTabBar == false
    }
    let last = app.staticTexts["검증 멤버 22"]
    let classTab = tabButton(4, in: app)
    for _ in 0 ..< 8 {
      if last.exists, last.isHittable, last.frame.maxY <= classTab.frame.minY {
        break
      }
      app.swipeUp()
    }
    attachDiagnostics(app, name: "tabs-last-member-scroll-position")
    XCTAssertTrue(last.isHittable, "Last member must be reachable above the bar")
    XCTAssertLessThanOrEqual(last.frame.maxY, classTab.frame.minY)
    attach(app, name: "tabs-last-member-above-bar")

    tabButton(2, in: app).tap()
    waitUntil("quick battle root hides tabs") {
      self.audit(in: app)?.selectedTab == 2 && self.audit(in: app)?.shouldHideTabBar == true
        && self.noCustomTabs(in: app)
    }
    XCTAssertEqual(app.tabBars.count, 0)
    attach(app, name: "tabs-quick-battle-hidden")
    let back = app.buttons.matching(NSPredicate(format: "identifier == %@ AND label == %@", "chevron.left", "뒤로"))
    XCTAssertTrue(back.firstMatch.waitForExistence(timeout: 5))
    // The empty-state bar exposes its full width as the button's accessibility frame.
    // Tap the visible back icon at the leading 16pt inset plus its 12pt half-width.
    back.firstMatch.coordinate(withNormalizedOffset: .zero)
      .withOffset(CGVector(dx: 28, dy: back.firstMatch.frame.height / 2)).tap()
    waitUntil("quick battle returns to class") {
      self.audit(in: app)?.selectedTab == 4 && self.audit(in: app)?.shouldHideTabBar == false
    }
    assertVisibleTabBar(in: app, selected: 4)

    tabButton(4, in: app).tap()
    waitUntil("class reselect resets to intro") {
      self.audit(in: app)?.classRouteKind == "intro"
        && self.audit(in: app)?.shouldHideTabBar == true && self.noCustomTabs(in: app)
    }
    XCTAssertEqual(app.tabBars.count, 0)
    attach(app, name: "tabs-class-reselected-intro")

    XCTAssertTrue(back.firstMatch.waitForExistence(timeout: 5))
    // The intro exposes the icon itself, unlike the full-width empty-state bar.
    back.firstMatch.tap()
    waitUntil("class intro exits to home instead of selecting itself") {
      self.audit(in: app)?.selectedTab == 0 && self.audit(in: app)?.shouldHideTabBar == false
    }
    assertVisibleTabBar(in: app, selected: 0)
    attach(app, name: "tabs-home-after-intro-back")
  }

  func testMountWhileKeyboardAlreadyOpenWithholdsBarUntilDismissed() {
    let app = launch(scenario: "keyboard-mount")
    let field = app.textFields["audit-keyboard-field"]
    XCTAssertTrue(field.waitForExistence(timeout: 5))
    field.tap()
    waitUntil("fixture keyboard open before mount") { app.keyboards.count > 0 }
    app.buttons["audit-mount-tabs"].tap()
    waitUntil("mounted shell detects existing keyboard") {
      guard let state = self.audit(in: app) else { return false }
      return state.mounted && state.isKeyboardVisible && state.shouldHideTabBar
        && self.noCustomTabs(in: app)
    }
    XCTAssertEqual(app.tabBars.count, 0)
    attach(app, name: "tabs-mounted-over-existing-keyboard")
    app.buttons["audit-dismiss-keyboard"].tap()
    waitUntil("bar appears after fixture keyboard dismissal") {
      guard let state = self.audit(in: app) else { return false }
      return !state.isKeyboardVisible && !state.shouldHideTabBar
    }
    assertVisibleTabBar(in: app, selected: 0)
    attach(app, name: "tabs-after-initial-keyboard-dismissed")
  }

  func testReportShowsBarAndBackPreservesDetailBar() throws {
    let app = launch(scenario: "report")
    waitUntil("report route shows custom bar") {
      self.audit(in: app)?.classRouteKind == "report"
        && self.audit(in: app)?.shouldHideTabBar == false
    }
    let original = try XCTUnwrap(audit(in: app))
    XCTAssertFalse(original.reportInstanceID.isEmpty)
    assertVisibleTabBar(in: app, selected: 4)
    XCTAssertFalse(app.buttons["xmark"].exists)
    XCTAssertTrue(app.staticTexts["종료"].exists)
    attach(app, name: "tabs-member-report-visible")

    let disclosure = app.buttons.containing(.staticText, identifier: "내가 남긴 의견 3개 보기").firstMatch
    let classTab = tabButton(4, in: app)
    for _ in 0 ..< 6 {
      if disclosure.exists, disclosure.isHittable, disclosure.frame.maxY <= classTab.frame.minY {
        break
      }
      app.scrollViews.firstMatch.swipeUp()
    }
    XCTAssertTrue(disclosure.isHittable)
    XCTAssertLessThanOrEqual(disclosure.frame.maxY, classTab.frame.minY)
    attach(app, name: "tabs-member-report-disclosure")
    disclosure.tap()
    waitUntil("report opinions expanded") { self.audit(in: app)?.reportShowsMyOpinions == true }
    let lastOpinion = app.staticTexts["토론을 들으며 연령만 낮추는 것보다 교정의 기준을 세우는 일이 중요하다고 느꼈어요."]
    for _ in 0 ..< 6 {
      if lastOpinion.exists, lastOpinion.isHittable, lastOpinion.frame.maxY <= classTab.frame.minY {
        break
      }
      app.scrollViews.firstMatch.swipeUp()
    }
    XCTAssertTrue(lastOpinion.isHittable)
    XCTAssertLessThanOrEqual(lastOpinion.frame.maxY, classTab.frame.minY)
    assertVisibleTabBar(in: app, selected: 4)
    attach(app, name: "tabs-member-report-expanded-bottom")

    tabButton(0, in: app).tap()
    waitUntil("home selected from report") { self.audit(in: app)?.selectedTab == 0 }
    assertVisibleTabBar(in: app, selected: 0)
    tabButton(4, in: app).tap()
    waitUntil("report state retained after tab roundtrip") {
      guard let state = self.audit(in: app) else { return false }
      return state.selectedTab == 4 && state.classRouteKind == "report"
        && state.reportInstanceID == original.reportInstanceID && state.reportShowsMyOpinions
        && state.classRouteCount == original.classRouteCount && !state.shouldHideTabBar
    }
    assertVisibleTabBar(in: app, selected: 4)
    attach(app, name: "tabs-member-report-restored")
    let back = app.buttons.matching(NSPredicate(format: "identifier == %@ AND label == %@", "chevron.left", "뒤로"))
    XCTAssertTrue(back.firstMatch.waitForExistence(timeout: 5))
    back.firstMatch.tap()
    waitUntil("participant detail preserves custom bar") {
      self.audit(in: app)?.classRouteKind == "detail"
        && self.audit(in: app)?.classRouteCount == original.classRouteCount - 1
        && self.audit(in: app)?.shouldHideTabBar == false
    }
    assertVisibleTabBar(in: app, selected: 4)
    attach(app, name: "tabs-returned-from-report")
  }
}

@MainActor
private extension MainTabInteractionTests {
  func launch(scenario: String) -> XCUIApplication {
    let app = XCUIApplication(bundleIdentifier: "com.picke.class-audit")
    activeApp = app
    app.launchEnvironment["PICKE_TAB_SCENARIO"] = scenario
    app.launch()
    XCTAssertTrue(app.staticTexts["audit-main-tab-state"].waitForExistence(timeout: 10))
    return app
  }

  private func audit(in app: XCUIApplication) -> AuditState? {
    guard let value = app.staticTexts["audit-main-tab-state"].value as? String,
          let data = value.data(using: .utf8) else { return nil }
    return try? JSONDecoder().decode(AuditState.self, from: data)
  }

  func tabButton(
    _ tab: Int,
    in app: XCUIApplication
  ) -> XCUIElement {
    let query = app.buttons.matching(identifier: "tab.\(tab)")
    if query.count != 1 {
      attachDiagnostics(app, name: "missing-tab-\(tab)")
    }
    XCTAssertEqual(query.count, 1, "Expected exactly one custom button for tab \(tab)")
    return query.firstMatch
  }

  func assertVisibleTabBar(
    in app: XCUIApplication,
    selected: Int
  ) {
    XCTAssertEqual(app.tabBars.count, 0)
    for tab in [0, 1, 2, 4, 3] {
      let button = tabButton(tab, in: app)
      XCTAssertTrue(button.isHittable)
      XCTAssertEqual(button.isSelected, tab == selected)
    }
  }

  func noCustomTabs(in app: XCUIApplication) -> Bool {
    [0, 1, 2, 4, 3].allSatisfy { app.buttons.matching(identifier: "tab.\($0)").count == 0 }
  }

  func waitUntil(
    _ description: String,
    condition: @escaping () -> Bool
  ) {
    let expectation = XCTNSPredicateExpectation(
      predicate: NSPredicate { _, _ in condition() },
      object: nil
    )
    let result = XCTWaiter.wait(for: [expectation], timeout: 10)
    if result != .completed, let activeApp {
      attachDiagnostics(activeApp, name: description)
    }
    XCTAssertEqual(result, .completed, description)
  }

  func attachDiagnostics(
    _ app: XCUIApplication,
    name: String
  ) {
    attach(app, name: name)
    let tree = XCTAttachment(string: app.debugDescription)
    tree.name = name + "-accessibility"
    tree.lifetime = .keepAlways
    add(tree)
    if let value = app.staticTexts["audit-main-tab-state"].value as? String {
      let state = XCTAttachment(string: value)
      state.name = name + "-state"
      state.lifetime = .keepAlways
      add(state)
    }
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
