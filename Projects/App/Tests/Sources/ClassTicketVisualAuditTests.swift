import ComposableArchitecture
import DomainAssembly
import FeatureAssembly
import PickeCoreUtility
@testable import Picke
import SwiftUI
import TCAFlow
import UIKit
import XCTest

final class ClassTicketVisualAuditTests: XCTestCase {
  @MainActor
  func testCaptureTicketEntryAndRegisteredScreens() async throws {
    guard ProcessInfo.processInfo.environment["PICKE_CLASS_VISUAL_AUDIT"] == "1" else {
      throw XCTSkip("Set PICKE_CLASS_VISUAL_AUDIT=1 to capture ticket screens")
    }

    let entry = ClassTicketFeature.State()

    var registered = ClassTicketFeature.State()
    registered.phase = .registered
    registered.registrationStartDate = try XCTUnwrap("2026.10.09".date(as: .yearMonthDayDotted))
    registered.expirationDate = try XCTUnwrap("2027.04.08".date(as: .yearMonthDayDotted))
    for (width, height) in [(402, 874), (375, 812)] {
      let size = CGSize(width: width, height: height)
      try await capture(entry, name: "ticket-entry-\(width)", size: size)
      try await capture(registered, name: "ticket-registered-\(width)", size: size)
    }
  }

  @MainActor
  private func capture(
    _ ticket: ClassTicketFeature.State,
    name: String,
    size: CGSize
  ) async throws {
    var state = MainTabCoordinator.State(selectedTab: MainTabCoordinator.Tab.classroom.rawValue)
    state.classState.routes.push(.ticket(ticket))
    let repository = MockClassRepository(rooms: [], availableRooms: [])
    let store = Store(initialState: state) {
      MainTabCoordinator()
        .dependency(\.classUseCase, repository)
        .dependency(\.classMockRepository, repository)
    }
    let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
    let window = UIWindow(windowScene: scene)
    window.frame = CGRect(origin: .zero, size: size)
    window.rootViewController = UIHostingController(rootView: MainTabView(store: store))
    window.makeKeyAndVisible()
    defer { window.isHidden = true }

    try await Task.sleep(for: .milliseconds(500))
    window.layoutIfNeeded()
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
  }
}
