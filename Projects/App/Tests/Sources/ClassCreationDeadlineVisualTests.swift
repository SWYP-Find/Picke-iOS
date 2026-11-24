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
  func testEditDeadlineLongErrorAndDisabledPanel() async throws {
    for enabled in [true, false] {
      try await captureEditDeadlinePanel(enabled: enabled)
    }
  }

  @MainActor
  private func captureEditDeadlinePanel(enabled: Bool) async throws {
    guard ProcessInfo.processInfo.environment["PICKE_CLASS_VISUAL_AUDIT"] == "1" else {
      throw XCTSkip("Enable PICKE_CLASS_VISUAL_AUDIT for mounted captures")
    }
    let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
    let previousKeyWindow = scene.windows.first { $0.isKeyWindow }
    let room = ClassRoom.mocks[0]
    let now = room.deadline.addingTimeInterval(-86400)
    var state = ClassCoordinator.State()
    var edit = ClassDeadlineEditFeature.State(room: room, instanceID: UUID(), referenceNow: now)
    edit.isDeadlineEnabled = enabled
    edit.errorMessage = "마감일 변경 결과를 확인하지 못했어요. 네트워크 연결을 확인하고 다시 시도해 주세요. 입력한 날짜는 유지됩니다."
    state.deadlineEdit = edit
    let store = Store(initialState: state) { ClassCoordinator().dependency(\.date.now, now) }
    let window = UIWindow(windowScene: scene)
    window.frame = CGRect(x: 0, y: 0, width: 402, height: 874)
    window.rootViewController = UIHostingController(rootView: ClassCoordinatorView(store: store)
      .environment(\.dynamicTypeSize, .medium))
    window.makeKeyAndVisible()
    defer {
      window.isHidden = true
      window.rootViewController = nil
      previousKeyWindow?.makeKey()
    }
    let directory = try FileManager.default.url(
      for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true
    ).appendingPathComponent("ClassCreationDeadlineAudit")
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    try await Task.sleep(for: .milliseconds(500))
    let image = UIGraphicsImageRenderer(bounds: window.bounds).image { _ in
      window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
    }
    let name = (enabled ? "edit-long-error" : "edit-disabled-long-error") + pickerCaptureSuffix
    try XCTUnwrap(image.pngData()).write(to: directory.appendingPathComponent(name + ".png"))
    let attachment = XCTAttachment(image: image)
    attachment.name = name
    attachment.lifetime = .keepAlways
    add(attachment)
    try assertDeadlinePanelGeometry(
      image,
      bottomInset: window.safeAreaInsets.bottom,
      hasWheel: enabled,
      hasError: true
    )
    XCTAssertEqual(store.deadlineEdit?.draftDeadline, room.deadline)
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
    XCTAssertEqual(store.deadlineSelection?.draftDeadline, now.addingTimeInterval(86400))
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
      let name = "creation-\(ai ? "ai" : "regular")-\(invalid ? "validation" : "wheel")" + pickerCaptureSuffix
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
    bottomInset: CGFloat,
    hasWheel: Bool = true,
    hasError: Bool = false
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
    if hasError {
      var containsErrorText = false
      for x in stride(from: CGFloat(16), through: image.size.width - 16, by: 3) {
        for y in stride(from: top + 18, through: top + 43, by: 3) {
          let color = try pixel(x, y)
          if Int(color[0]) - Int(color[1]) > 20 { containsErrorText = true }
        }
        try white(x, top + 45)
      }
      XCTAssertTrue(containsErrorText, "Error text must remain inside the reserved error slot")
    }
    // Figma12772:36346: full-width32pt highlight at y117...149.
    if #available(iOS 18, *), hasWheel {
      for y in [top + 118, top + 148] {
        let fill = try pixel(30, y)
        XCTAssertTrue(fill.prefix(3).allSatisfy { abs(Int($0) - 245) <= 2 }, "Expected selection fill: \(fill)")
      }
      try white(30, top + 115)
      try white(30, top + 151)
    }
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

  private var pickerCaptureSuffix: String {
    if #available(iOS 18, *) { return "" }
    return "-native17"
  }
}
