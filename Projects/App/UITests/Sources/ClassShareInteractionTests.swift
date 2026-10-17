//
//  ClassShareInteractionTests.swift
//  PickeClassUITests
//
//  Created by Picke on 10/17/26.
//

import UIKit
import Vision
import XCTest
import XCUIAutomation

@MainActor
final class ClassShareInteractionTests: XCTestCase {
  private let copyMarkers: Set<String> = ["복사", "copy"]
  private let sheetMarkers: Set<String> = ["airdrop", "복사", "copy", "이미지저장", "saveimage"]

  override func setUpWithError() throws {
    continueAfterFailure = false
  }

  func testFinalVoteShareSheetClosesAndReopens() async throws {
    let app = XCUIApplication(bundleIdentifier: "com.picke.class-audit")
    app.launchEnvironment["PICKE_SHARE_SCENARIO"] = "final-vote"
    app.launch()
    let shareButtons = app.buttons.matching(NSPredicate(format: "label == %@", "공유하기"))
    XCTAssertTrue(shareButtons.firstMatch.waitForExistence(timeout: 10), app.debugDescription)
    XCTAssertEqual(shareButtons.count, 1)
    XCTAssertTrue(shareButtons.firstMatch.isHittable)

    let baseline = try await stableBaseline()
    let baselineText = try recognizedText(in: baseline)
    attach(baseline, text: baselineText, name: "share-ui-baseline")
    XCTAssertTrue(sheetMarkers.isDisjoint(with: baselineText))
    XCTAssertEqual(app.sheets.count, 0)

    for name in ["opened", "reopened"] {
      shareButtons.firstMatch.tap()
      try await waitForOpenSheet(in: app, name: "share-ui-" + name)
      let close = try XCTUnwrap(hittableCloseButtons(in: app).first, app.debugDescription)
      close.tap()
      try await waitForDismissal(
        in: app,
        baseline: baseline,
        name: "share-ui-" + name + "-dismissed"
      )
      try await Task.sleep(for: .milliseconds(500))
      try await waitForDismissal(
        in: app,
        baseline: baseline,
        name: "share-ui-" + name + "-stable"
      )
    }
  }
}

private extension ClassShareInteractionTests {
  func stableBaseline() async throws -> XCUIScreenshot {
    var previous = XCUIScreen.main.screenshot()
    for _ in 0 ..< 20 {
      try await Task.sleep(for: .milliseconds(250))
      let current = XCUIScreen.main.screenshot()
      let difference = try pixelDifference(current, baseline: previous, lowerHalfOnly: true)
      if difference <= 0.03 {
        attachText("lower-half stabilization difference: \(difference)", name: "share-ui-baseline-stability")
        return current
      }
      previous = current
    }
    try attach(previous, text: recognizedText(in: previous), name: "share-ui-unstable-baseline")
    throw AuditError.unstableBaseline
  }

  func waitForOpenSheet(
    in app: XCUIApplication,
    name: String
  ) async throws {
    var screenshot = XCUIScreen.main.screenshot()
    var text = try recognizedText(in: screenshot)
    var previousVisibleScreenshot: XCUIScreenshot?
    var stableFrames = 0
    for _ in 0 ..< 40 {
      screenshot = XCUIScreen.main.screenshot()
      text = try recognizedText(in: screenshot)
      if !copyMarkers.isDisjoint(with: text), !hittableCloseButtons(in: app).isEmpty {
        if let previousVisibleScreenshot {
          let difference = try pixelDifference(
            screenshot,
            baseline: previousVisibleScreenshot,
            lowerHalfOnly: false
          )
          stableFrames = difference <= 0.003 ? stableFrames + 1 : 0
          // Controls can appear before the sheet reaches its final position.
          if stableFrames >= 2 {
            attach(screenshot, text: text, name: name)
            attachText("full-screen stabilization difference: \(difference)", name: name + "-stability")
            attachText(app.debugDescription, name: name + "-accessibility")
            return
          }
        }
        previousVisibleScreenshot = screenshot
      } else {
        previousVisibleScreenshot = nil
        stableFrames = 0
      }
      try await Task.sleep(for: .milliseconds(250))
    }
    attach(screenshot, text: text, name: name + "-failed")
    attachText(app.debugDescription, name: name + "-failed-accessibility")
    throw AuditError.sheetNotVisible
  }

  func waitForDismissal(
    in app: XCUIApplication,
    baseline: XCUIScreenshot,
    name: String
  ) async throws {
    var screenshot = XCUIScreen.main.screenshot()
    var text = try recognizedText(in: screenshot)
    var difference = 1.0
    for _ in 0 ..< 40 {
      screenshot = XCUIScreen.main.screenshot()
      text = try recognizedText(in: screenshot)
      difference = try pixelDifference(screenshot, baseline: baseline, lowerHalfOnly: true)
      if sheetMarkers.isDisjoint(with: text), app.sheets.count == 0,
         hittableCloseButtons(in: app).isEmpty,
         app.buttons["공유하기"].isHittable, difference <= 0.03
      {
        attach(screenshot, text: text, name: name)
        attachText("lower-half baseline difference: \(difference)", name: name + "-difference")
        return
      }
      try await Task.sleep(for: .milliseconds(250))
    }
    attach(screenshot, text: text, name: name + "-failed")
    attachText(
      "lower-half baseline difference: \(difference)\n\(app.debugDescription)",
      name: name + "-failed-accessibility"
    )
    throw AuditError.sheetNotDismissed
  }

  func hittableCloseButtons(in app: XCUIApplication) -> [XCUIElement] {
    app.buttons.matching(NSPredicate(format: "label IN %@", ["Close", "닫기"]))
      .allElementsBoundByIndex.filter(\.isHittable)
  }

  func recognizedText(in screenshot: XCUIScreenshot) throws -> Set<String> {
    let image = try XCTUnwrap(screenshot.image.cgImage)
    let request = VNRecognizeTextRequest()
    request.recognitionLevel = .accurate
    request.recognitionLanguages = ["ko-KR", "en-US"]
    request.usesLanguageCorrection = false
    try VNImageRequestHandler(cgImage: image).perform([request])
    return Set((request.results ?? []).compactMap { observation in
      observation.topCandidates(1).first?.string
        .components(separatedBy: .whitespacesAndNewlines).joined().lowercased()
    })
  }

  func pixelDifference(
    _ screenshot: XCUIScreenshot,
    baseline: XCUIScreenshot,
    lowerHalfOnly: Bool
  ) throws -> Double {
    let current = try pixels(in: screenshot, lowerHalfOnly: lowerHalfOnly)
    let original = try pixels(in: baseline, lowerHalfOnly: lowerHalfOnly)
    var total = 0
    for index in current.indices where index % 4 != 3 {
      total += abs(Int(current[index]) - Int(original[index]))
    }
    return Double(total) / Double(32 * 32 * 3 * 255)
  }

  func pixels(
    in screenshot: XCUIScreenshot,
    lowerHalfOnly: Bool
  ) throws -> [UInt8] {
    let image = try XCTUnwrap(screenshot.image.cgImage)
    let originY = lowerHalfOnly ? image.height / 2 : 0
    let region = try XCTUnwrap(image.cropping(to: CGRect(
      x: 0,
      y: originY,
      width: image.width,
      height: image.height - originY
    )))
    var pixels = [UInt8](repeating: 0, count: 32 * 32 * 4)
    try pixels.withUnsafeMutableBytes { buffer in
      let context = try XCTUnwrap(CGContext(
        data: buffer.baseAddress,
        width: 32,
        height: 32,
        bitsPerComponent: 8,
        bytesPerRow: 32 * 4,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
      ))
      context.interpolationQuality = .low
      context.draw(region, in: CGRect(x: 0, y: 0, width: 32, height: 32))
    }
    return pixels
  }

  func attach(
    _ screenshot: XCUIScreenshot,
    text: Set<String>,
    name: String
  ) {
    let image = XCTAttachment(screenshot: screenshot)
    image.name = name
    image.lifetime = .keepAlways
    add(image)
    attachText(text.sorted().joined(separator: "\n"), name: name + "-ocr")
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

  enum AuditError: Error {
    case unstableBaseline
    case sheetNotVisible
    case sheetNotDismissed
  }
}
