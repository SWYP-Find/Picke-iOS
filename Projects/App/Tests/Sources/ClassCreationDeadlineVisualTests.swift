//
//  ClassCreationDeadlineVisualTests.swift
//  PickeTests
//
//  Created by Picke on 10/15/26.
//

import ComposableArchitecture
import DomainAssembly
import FeatureAssembly
@testable import Picke
import SwiftUI
import TCAFlow
import UIKit
import XCTest

final class ClassCreationDeadlineVisualTests: XCTestCase {
  @MainActor
  func testAICreationDeadlinePanel() async throws {
    try await captureCreationDeadlinePanel(ai: true)
  }

  @MainActor
  func testRegularCreationDeadlinePanel() async throws {
    try await captureCreationDeadlinePanel(ai: false)
  }

  @MainActor
  private func captureCreationDeadlinePanel(ai: Bool) async throws {
    guard ProcessInfo.processInfo.environment["PICKE_CLASS_VISUAL_AUDIT"] == "1" else {
      throw XCTSkip("Enable PICKE_CLASS_VISUAL_AUDIT for mounted captures")
    }
    let now = Date(timeIntervalSince1970: 1_800_000_000)
    let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
    let directory = try FileManager.default.url(
      for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true
    ).appendingPathComponent("ClassCreationDeadlineAudit")
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    var state = ClassCoordinator.State()
    let setting = ai
      ? ClassSettingFeature.State(aiQuestion: .examples[0], filter: .init(), deadline: now.addingTimeInterval(86400))
      : ClassSettingFeature.State(battle: ClassRoom.mockJoinable.battle, deadline: now.addingTimeInterval(86400))
    state.routes.push(.setting(setting))
    let store = Store(initialState: state) {
      ClassCoordinator().dependency(\.date.now, now)
    }
    let window = UIWindow(windowScene: scene)
    window.frame = CGRect(x: 0, y: 0, width: 402, height: 874)
    window.rootViewController = UIHostingController(rootView: ClassCoordinatorView(store: store)
      .environment(\.locale, Locale(identifier: "ko_KR"))
      .environment(\.dynamicTypeSize, .medium))
    let previousKeyWindow = scene.windows.first { $0.isKeyWindow && $0 !== window }
    defer {
      window.isHidden = true
      window.rootViewController = nil
      previousKeyWindow?.makeKey()
    }
    window.makeKeyAndVisible()
    try await Task.sleep(for: .milliseconds(400))
    store.send(.router(.routeAction(id: 1, action: .setting(.view(.deadlineFieldTapped)))))
    try await Task.sleep(for: .milliseconds(400))
    XCTAssertNotNil(store.deadlineSelection)
    for invalid in [false, true] {
      if invalid {
        store.send(.deadlineSelection(.presented(.binding(.set(\.draftDeadline, now.addingTimeInterval(-1))))))
        store.send(.deadlineSelection(.presented(.view(.confirmTapped))))
      }
      try await Task.sleep(for: .milliseconds(400))
      window.layoutIfNeeded()
      let image = UIGraphicsImageRenderer(bounds: window.bounds).image { _ in
        window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
      }
      let name = "creation-\(ai ? "ai" : "regular")-\(invalid ? "validation" : "wheel")"
      try XCTUnwrap(image.pngData()).write(to: directory.appendingPathComponent(name + ".png"))
      let attachment = XCTAttachment(image: image)
      attachment.name = name
      attachment.lifetime = .keepAlways
      add(attachment)
      try assertDeadlinePanelGeometry(image, bottomInset: window.safeAreaInsets.bottom)
    }
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

}
