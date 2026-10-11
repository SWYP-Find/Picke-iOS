//
//  ClassFlowVisualAuditTests.swift
//  PickeTests
//
//  Created by Picke on 10/11/26.
//

import AudioPlayerServiceInterface
import ComposableArchitecture
import DomainAssembly
import FeatureAssembly
@testable import Picke
import PickeAnalyticsInterface
import PickeCoreUtility
import SwiftUI
import TCAFlow
import UIKit
import XCTest

/// Run explicitly with PICKE_CLASS_VISUAL_AUDIT=1. These images are evidence for
/// manual Figma comparison, not snapshot assertions or proof of design parity.
final class ClassFlowVisualAuditTests: XCTestCase {
  @MainActor
  func testClassFinalVoteSharePresentation() async throws {
    guard ProcessInfo.processInfo.environment["PICKE_CLASS_VISUAL_AUDIT"] == "1" else {
      throw XCTSkip("Set PICKE_CLASS_VISUAL_AUDIT=1 to verify Class share presentation")
    }
    let room = ClassRoom.mockJoinable
    let session = ClassMockChatSession()
    let battleID = await session.register(room: room)
    let store = Store(initialState: PreVoteFeature.State(battleId: battleID, voteMode: .post)) {
      PreVoteFeature()
        .dependency(\.battleUseCase, session)
        .dependency(\.perspectiveUseCase, session)
        .dependency(\.shareUseCase, .testValue)
        .dependency(\.analyticsUseCase, .testValue)
    }
    let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
    let window = UIWindow(windowScene: scene)
    let host = UIHostingController(rootView: ClassVoteView(store: store, room: room))
    window.rootViewController = host
    window.frame = scene.coordinateSpace.bounds
    window.makeKeyAndVisible()
    defer { window.isHidden = true }

    func waitFor(_ description: String, until predicate: () -> Bool) async throws {
      for _ in 0 ..< 100 {
        if predicate() {
          return
        }
        try await Task.sleep(for: .milliseconds(50))
      }
      XCTFail("Class share did not reach: \(description)")
      throw CaptureError.contentNotReady
    }
    func activityController(in controller: UIViewController) -> UIActivityViewController? {
      if let activity = controller as? UIActivityViewController {
        return activity
      }
      if let presented = controller.presentedViewController,
         let activity = activityController(in: presented)
      {
        return activity
      }
      return controller.children.lazy.compactMap { activityController(in: $0) }.first
    }

    try await waitFor("loaded final vote") {
      store.battle != nil && !store.detailLoadFailed && store.viewState == .loaded
    }
    store.send(.view(.shareTapped))
    try await waitFor("share sheet") {
      store.shareSnapshotRequest == nil && store.shareItem != nil
        && activityController(in: host)?.view.window != nil
    }
    let shareID = try XCTUnwrap(store.shareItem?.id)
    // A nil-reset observation must not create a second item and re-present the sheet.
    for _ in 0 ..< 10 {
      try await Task.sleep(for: .milliseconds(50))
      XCTAssertEqual(store.shareItem?.id, shareID)
    }
    let shareController = try XCTUnwrap(activityController(in: host))
    let shareWindow = try XCTUnwrap(shareController.view.window)
    shareWindow.layoutIfNeeded()
    let image = UIGraphicsImageRenderer(bounds: shareWindow.bounds).image { _ in
      shareWindow.drawHierarchy(in: shareWindow.bounds, afterScreenUpdates: true)
    }
    let directory = try FileManager.default.url(
      for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true
    ).appendingPathComponent("ClassVisualAudit", isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    try XCTUnwrap(image.pngData()).write(to: directory.appendingPathComponent("final-vote-share-sheet.png"))
    let attachment = XCTAttachment(image: image)
    attachment.name = "final-vote-share-sheet"
    attachment.lifetime = .keepAlways
    add(attachment)

    store.send(.binding(.set(\.shareItem, nil)))
    try await waitFor("dismissed share sheet") {
      store.shareItem == nil && host.presentedViewController == nil
    }
    try await Task.sleep(for: .milliseconds(500))
    XCTAssertNil(store.shareItem)
    XCTAssertNil(store.shareSnapshotRequest)
    XCTAssertNil(host.presentedViewController)
    XCTAssertEqual(store.voteMode, .post)
    XCTAssertNotNil(store.battle)
  }

  @MainActor
  func testPresentClassTabForInteractiveAudit() async throws {
    guard ProcessInfo.processInfo.environment["PICKE_CLASS_INTERACTIVE_AUDIT"] == "1" else {
      throw XCTSkip("Set PICKE_CLASS_INTERACTIVE_AUDIT=1 for a manual Class tab session")
    }
    let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
    let window = UIWindow(windowScene: scene)
    let memberAudit = ProcessInfo.processInfo.environment["PICKE_CLASS_MEMBER_AUDIT"] == "1"
    let repository = memberAudit ? MockClassRepository(rooms: memberRooms, availableRooms: []) : MockClassRepository()
    let session = ClassMockChatSession()
    var state = MainTabCoordinator.State(selectedTab: MainTabCoordinator.Tab.classroom.rawValue)
    if memberAudit {
      state.classState.routes.push(.myClasses(.init()))
    }
    let store = Store(initialState: state) {
      MainTabCoordinator()
        .dependency(\.classUseCase, repository)
        .dependency(\.classMockRepository, repository)
        .dependency(\.classMockChatSession, session)
        .dependency(\.classMockAudioPlayer, ClassMockAudioPlayer())
    }
    window.rootViewController = UIHostingController(rootView: MainTabView(store: store))
    window.frame = scene.coordinateSpace.bounds
    window.makeKeyAndVisible()
    defer { window.isHidden = true }
    try await Task.sleep(for: .seconds(180))
  }

  @MainActor
  func testCaptureMemberManagementFlow() async throws {
    guard ProcessInfo.processInfo.environment["PICKE_CLASS_VISUAL_AUDIT"] == "1" else {
      throw XCTSkip("Set PICKE_CLASS_VISUAL_AUDIT=1 to capture member management")
    }
    let rooms = memberRooms
    let repository = MockClassRepository(rooms: rooms, availableRooms: [])
    var state = MainTabCoordinator.State(selectedTab: MainTabCoordinator.Tab.classroom.rawValue)
    state.classState.routes.push(.myClasses(.init()))
    let store = withDependencies {
      $0.context = .test
      $0.uuid = .incrementing
    } operation: {
      Store(initialState: state) {
        MainTabCoordinator()
          .dependency(\.classUseCase, repository)
          .dependency(\.classMockRepository, repository)
          .dependency(\.classMockChatSession, ClassMockChatSession())
          .dependency(\.classMockAudioPlayer, ClassMockAudioPlayer())
      }
    }
    let routeID = state.classState.routes.count - 1
    func send(_ action: MyClassFeature.Action) {
      // Presentation effects live until dismissal; wait for the expected state below.
      store.send(.classroom(.router(.routeAction(id: routeID, action: .myClasses(action)))))
    }
    func waitFor(_ description: String, until predicate: (MyClassFeature.State) -> Bool) async throws {
      for _ in 0 ..< 100 {
        if case let .myClasses(list)? = store.classState.routes.last?.screen, predicate(list) {
          return
        }
        try await Task.sleep(for: .milliseconds(50))
      }
      XCTFail("Member management did not reach: \(description)")
      throw CaptureError.contentNotReady
    }
    let directory = try FileManager.default.url(
      for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true
    ).appendingPathComponent("ClassMemberVisualAudit", isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
    let window = UIWindow(windowScene: scene)
    let host = UIHostingController(rootView: MainTabView(store: store))
    window.rootViewController = host
    window.frame = scene.coordinateSpace.bounds
    window.makeKeyAndVisible()
    defer { window.isHidden = true }
    func save(_ name: String) async throws {
      try await Task.sleep(for: .milliseconds(400))
      host.view.layoutIfNeeded()
      CATransaction.flush()
      let image = UIGraphicsImageRenderer(bounds: window.bounds).image { _ in
        window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
      }
      try XCTUnwrap(image.pngData()).write(to: directory.appendingPathComponent(name + ".png"))
      let attachment = XCTAttachment(image: image)
      attachment.name = name
      attachment.lifetime = .keepAlways
      add(attachment)
    }
    send(.view(.onAppear))
    try await waitFor("loaded member list") { !$0.isLoading && $0.rooms.map(\.id) == rooms.map(\.id) }
    try await save("01-member-list")
    send(.view(.managementTapped(rooms[0].id)))
    try await waitFor("management sheet") { $0.modal != nil && $0.selectedRoomID == rooms[0].id }
    XCTAssertFalse(store.classState.showsTabBar)
    try await save("02-member-management")
    send(.view(.leaveTapped))
    try await waitFor("leave confirmation") { $0.modal == nil && $0.customAlert != nil }
    XCTAssertFalse(store.classState.showsTabBar)
    try await save("03-member-leave-confirm")
    send(.customAlert(.presented(.cancelTapped)))
    try await waitFor("cancelled leave") { $0.customAlert == nil && $0.pendingConfirmation == nil }
    XCTAssertTrue(store.classState.showsTabBar)
    let roomsAfterCancel = try await repository.fetchMyClasses()
    XCTAssertEqual(roomsAfterCancel.count, 3)
    send(.view(.managementTapped(rooms[0].id)))
    send(.view(.leaveTapped))
    send(.customAlert(.presented(.confirmTapped)))
    try await waitFor("completed leave cleanup") {
      !$0.isLeaving && $0.rooms.map(\.id) == rooms.dropFirst().map(\.id)
    }
    XCTAssertTrue(store.classState.showsTabBar)
    let remaining = try await repository.fetchMyClasses()
    XCTAssertEqual(remaining.map(\.id), rooms.dropFirst().map(\.id))
    try await save("04-member-left")
  }

  private var memberRooms: [ClassRoom] {
    ClassRoom.mocks.map { room in
      ClassRoom(
        id: room.id, name: room.name, joinCode: room.joinCode, battle: room.battle,
        deadline: Date(timeIntervalSince1970: 1_790_154_000),
        memberCount: room.memberCount, role: .member, status: room.status,
        allowsAnonymousOpinion: room.allowsAnonymousOpinion, requiresComment: room.requiresComment
      )
    }
  }

  @MainActor
  func testCaptureEmptyClassComments() async throws {
    guard ProcessInfo.processInfo.environment["PICKE_CLASS_VISUAL_AUDIT"] == "1" else {
      throw XCTSkip("Set PICKE_CLASS_VISUAL_AUDIT=1 to capture empty comments")
    }
    let room = ClassRoom.mockJoinable
    let session = ClassMockChatSession()
    let battleID = await session.register(room: room)
    let store = withDependencies {
      $0.context = .test
    } operation: {
      Store(initialState: ChatCoordinator.State(route: .comment(battleId: battleID))) {
        ChatCoordinator()
          .dependency(\.battleUseCase, session)
          .dependency(\.perspectiveUseCase, session)
          .dependency(\.commentUseCase, session)
          .dependency(\.analyticsUseCase, .testValue)
      }
    }
    let (image, _) = try await capture(
      AnyView(ClassChatCoordinatorView(store: store, roomsByBattleID: [battleID: room])),
      ready: {
        guard case let .comment(value)? = store.routes.last?.screen else { return false }
        return !value.title.isEmpty && !value.isLoadingComments && !value.isLoadingStats
      },
      includeScrollBottom: false
    )
    guard case let .comment(value)? = store.routes.last?.screen else {
      return XCTFail("Expected the Class comment route")
    }
    XCTAssertTrue(value.comments.isEmpty)
    let directory = try FileManager.default.url(
      for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true
    ).appendingPathComponent("ClassVisualAudit", isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    try XCTUnwrap(image.pngData()).write(to: directory.appendingPathComponent("15-comments-empty.png"))
    let attachment = XCTAttachment(image: image)
    attachment.name = "15-comments-empty"
    attachment.lifetime = .keepAlways
    add(attachment)
  }

  @MainActor
  func testCaptureClassJoinOverlays() async throws {
    guard ProcessInfo.processInfo.environment["PICKE_CLASS_VISUAL_AUDIT"] == "1" else {
      throw XCTSkip("Set PICKE_CLASS_VISUAL_AUDIT=1 to capture Class join overlays")
    }
    let room = ClassRoom.mockJoinable
    let repository = MockClassRepository(rooms: [], availableRooms: [room])
    let directory = try FileManager.default.url(
      for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true
    ).appendingPathComponent("ClassVisualAudit", isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

    func save(
      _ name: String,
      view: AnyView,
      ready: @escaping @MainActor () -> Bool,
      viewport: CGSize? = nil,
      focusTextField: Bool = false
    ) async throws {
      let (image, _) = try await capture(
        view,
        ready: ready,
        includeScrollBottom: false,
        viewport: viewport,
        focusTextField: focusTextField
      )
      try XCTUnwrap(image.pngData()).write(to: directory.appendingPathComponent(name + ".png"))
      let attachment = XCTAttachment(image: image)
      attachment.name = name
      attachment.lifetime = .keepAlways
      add(attachment)
    }

    let valid = Store(initialState: ClassIntroFeature.State()) {
      ClassIntroFeature().dependency(\.classUseCase, repository)
    }
    valid.send(.view(.joinTapped))
    valid.send(.join(.presented(.binding(.set(\.joinCode, room.joinCode)))))
    try await save(
      "join-valid-code-overlay",
      view: AnyView(ClassIntroView(store: valid)),
      ready: { valid.join?.joinCode == room.joinCode && valid.join?.canFindClass == true }
    )
    valid.send(.join(.presented(.view(.findTapped))))
    try await save(
      "join-valid-name-overlay",
      view: AnyView(ClassIntroView(store: valid)),
      ready: { valid.join?.mode == .nickname && valid.join?.preview?.id == room.id }
    )

    let invalid = Store(initialState: ClassIntroFeature.State()) {
      ClassIntroFeature().dependency(\.classUseCase, repository)
    }
    invalid.send(.view(.joinTapped))
    invalid.send(.join(.presented(.binding(.set(\.joinCode, "BAD123")))))
    invalid.send(.join(.presented(.view(.findTapped))))
    try await save(
      "join-invalid-code-overlay",
      view: AnyView(ClassIntroView(store: invalid)),
      ready: { invalid.join?.errorMessage == ClassError.invalidCode.message && invalid.join?.isLoading == false }
    )

    let duplicate = Store(initialState: ClassIntroFeature.State()) {
      ClassIntroFeature().dependency(\.classUseCase, repository)
    }
    duplicate.send(.view(.joinTapped))
    duplicate.send(.join(.presented(.binding(.set(\.joinCode, room.joinCode)))))
    duplicate.send(.join(.presented(.view(.findTapped))))
    for _ in 0 ..< 50 where duplicate.join?.mode != .nickname {
      try await Task.sleep(for: .milliseconds(100))
    }
    guard duplicate.join?.mode == .nickname else { throw CaptureError.contentNotReady }
    duplicate.send(.join(.presented(.binding(.set(\.nickname, "운영자")))))
    duplicate.send(.join(.presented(.view(.joinTapped))))
    try await save(
      "join-duplicate-name-overlay",
      view: AnyView(ClassIntroView(store: duplicate)),
      ready: {
        duplicate.join?.nicknameErrorMessage == ClassError.duplicateName.message
          && duplicate.join?.isLoading == false
      }
    )
    duplicate.send(.join(.presented(.binding(.set(\.nickname, "1234567890123")))))
    try await save(
      "join-name-overlength-overlay",
      view: AnyView(ClassIntroView(store: duplicate)),
      ready: {
        duplicate.join?.nicknameCharacterCount == 13
          && duplicate.join?.nicknameErrorMessage == nil
          && duplicate.join?.nicknameValidationMessage != nil
          && duplicate.join?.canJoin == false
      }
    )

    let owner = ClassRoom.mocks[0]
    let ownerRepository = MockClassRepository(rooms: [owner], availableRooms: [])
    let ownerStore = Store(initialState: ClassShareFeature.State(room: owner)) {
      ClassShareFeature().dependency(\.classMockRepository, ownerRepository)
    }
    ownerStore.send(.view(.enterClassTapped))
    ownerStore.send(.join(.presented(.binding(.set(\.nickname, "김선생")))))
    try await save(
      "join-owner-name-overlay",
      view: AnyView(ClassShareView(store: ownerStore)),
      ready: { ownerStore.join?.mode == .ownerName && ownerStore.join?.canJoin == true }
    )

    let compact = Store(initialState: ClassIntroFeature.State()) {
      ClassIntroFeature().dependency(\.classUseCase, repository)
    }
    compact.send(.view(.joinTapped))
    compact.send(.join(.presented(.binding(.set(\.joinCode, room.joinCode)))))
    try await save(
      "join-valid-code-overlay-keyboard-attempt",
      view: AnyView(ClassIntroView(store: compact)),
      ready: { compact.join?.canFindClass == true },
      focusTextField: true
    )

    // Resized host on the current simulator, not a native 375x667 device screenshot.
    try await save(
      "join-valid-code-overlay-resized-375x667",
      view: AnyView(ClassIntroView(store: compact)),
      ready: { compact.join?.canFindClass == true },
      viewport: CGSize(width: 375, height: 667)
    )
  }

  @MainActor
  func testCaptureClassFlowFrames() async throws {
    guard ProcessInfo.processInfo.environment["PICKE_CLASS_VISUAL_AUDIT"] == "1" else {
      throw XCTSkip("Set PICKE_CLASS_VISUAL_AUDIT=1 to capture the Class user flow")
    }

    let directory = try FileManager.default.url(
      for: .documentDirectory,
      in: .userDomainMask,
      appropriateFor: nil,
      create: true
    ).appendingPathComponent("ClassVisualAudit", isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

    let frames = try await withDependencies {
      $0.context = .test
      $0.uuid = .incrementing
    } operation: {
      try await makeFrames()
    }
    var records: [Record] = []
    var imageCount = 0
    for frame in frames {
      guard let view = frame.view else {
        records.append(.init(
          number: frame.number,
          title: frame.title,
          status: "unavailable",
          detail: frame.detail,
          width: nil,
          height: nil
        ))
        continue
      }
      let (image, bottomImage) = try await capture(
        view,
        ready: frame.ready,
        includeScrollBottom: [19, 23, 25].contains(frame.number)
      )
      let name = String(format: "%02d", frame.number) + "-" + frame.slug + ".png"
      try XCTUnwrap(image.pngData()).write(to: directory.appendingPathComponent(name))
      imageCount += 1
      let attachment = XCTAttachment(image: image)
      attachment.name = name
      attachment.lifetime = .keepAlways
      add(attachment)
      if let bottomImage {
        let bottomName = String(format: "%02d", frame.number) + "-" + frame.slug + "-bottom.png"
        try XCTUnwrap(bottomImage.pngData()).write(to: directory.appendingPathComponent(bottomName))
        imageCount += 1
        let bottomAttachment = XCTAttachment(image: bottomImage)
        bottomAttachment.name = bottomName
        bottomAttachment.lifetime = .keepAlways
        add(bottomAttachment)
      }
      records.append(.init(
        number: frame.number,
        title: frame.title,
        status: "captured; visual comparison pending",
        detail: frame.detail,
        width: image.cgImage?.width,
        height: image.cgImage?.height
      ))
    }

    let manifest = try JSONEncoder().encode(records)
    try manifest.write(to: directory.appendingPathComponent("manifest.json"))
    XCTAssertEqual(records.count, 28)
    XCTAssertEqual(records.filter { $0.status == "captured; visual comparison pending" }.count, 28)
    XCTAssertEqual(imageCount, 31)
  }

  private struct Frame {
    let number: Int
    let title: String
    let slug: String
    let detail: String
    let view: AnyView?
    let ready: (@MainActor () -> Bool)?
  }

  private struct Record: Codable {
    let number: Int
    let title: String
    let status: String
    let detail: String
    let width: Int?
    let height: Int?
  }

  private enum CaptureError: Error {
    case contentNotReady
    case scrollDidNotReachBottom
    case duplicateBottomCapture
  }

  @MainActor
  private func capture(
    _ view: AnyView,
    ready: (@MainActor () -> Bool)?,
    includeScrollBottom: Bool,
    viewport: CGSize? = nil,
    focusTextField: Bool = false
  ) async throws -> (UIImage, UIImage?) {
    let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
    let window = UIWindow(windowScene: scene)
    let host = UIHostingController(rootView: view)
    window.rootViewController = host
    window.frame = CGRect(origin: .zero, size: viewport ?? scene.coordinateSpace.bounds.size)
    window.makeKeyAndVisible()
    defer { window.isHidden = true }
    host.view.frame = window.bounds
    host.view.setNeedsLayout()
    host.view.layoutIfNeeded()
    await Task.yield()
    if let ready {
      for _ in 0 ..< 50 {
        if ready() {
          break
        }
        try await Task.sleep(for: .milliseconds(100))
      }
      guard ready() else {
        XCTFail("Async content did not finish loading before capture")
        throw CaptureError.contentNotReady
      }
    }
    if focusTextField {
      let textField = firstTextField(in: host.view)
      XCTAssertNotNil(textField, "Join overlay did not expose a native text field")
      _ = textField?.becomeFirstResponder()
      try await Task.sleep(for: .milliseconds(400))
      XCTAssertTrue(textField?.isFirstResponder == true, "Join code field did not take native focus")
    }
    // The report charts animate for 0.8 seconds after their data arrives.
    try await Task.sleep(for: includeScrollBottom ? .milliseconds(800) : .milliseconds(400))
    try await Task.sleep(for: .milliseconds(17))
    host.view.layoutIfNeeded()
    CATransaction.flush()

    let renderer = UIGraphicsImageRenderer(bounds: window.bounds)
    let image = renderer.image { _ in
      window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
      if focusTextField {
        for overlay in scene.windows where overlay !== window && !overlay.isHidden
          && overlay.windowLevel > window.windowLevel
        {
          overlay.drawHierarchy(in: overlay.convert(overlay.bounds, to: window), afterScreenUpdates: true)
        }
      }
    }
    var bottomImage: UIImage?
    if includeScrollBottom {
      let scrollView = try XCTUnwrap(verticalScrollViews(in: host.view, window: window).max {
        $0.bounds.height < $1.bounds.height
      }, "Expected visible report content to have a vertical scroll view")
      let bottomOffset = max(
        -scrollView.adjustedContentInset.top,
        scrollView.contentSize.height - scrollView.bounds.height + scrollView.adjustedContentInset.bottom
      )
      guard bottomOffset > scrollView.contentOffset.y + 1 else {
        XCTFail("Report scroll view has no uncaptured content below the current viewport")
        throw CaptureError.scrollDidNotReachBottom
      }
      scrollView.setContentOffset(CGPoint(
        x: scrollView.contentOffset.x,
        y: bottomOffset
      ), animated: false)
      try await Task.sleep(for: .milliseconds(100))
      host.view.layoutIfNeeded()
      guard abs(scrollView.contentOffset.y - bottomOffset) <= 1 else {
        XCTFail("Report scroll view did not reach its bottom offset")
        throw CaptureError.scrollDidNotReachBottom
      }
      CATransaction.flush()
      bottomImage = renderer.image { _ in
        window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
      }
      let topPixels = try XCTUnwrap(image.cgImage?.dataProvider?.data) as Data
      let bottomPixels = try XCTUnwrap(bottomImage?.cgImage?.dataProvider?.data) as Data
      guard topPixels != bottomPixels else {
        XCTFail("Report bottom capture is identical to its top capture")
        throw CaptureError.duplicateBottomCapture
      }
    }
    return (image, bottomImage)
  }

  @MainActor
  private func firstTextField(in view: UIView) -> UITextField? {
    if let field = view as? UITextField {
      return field
    }
    return view.subviews.lazy.compactMap(firstTextField(in:)).first
  }

  @MainActor
  private func verticalScrollViews(in view: UIView, window: UIWindow) -> [UIScrollView] {
    guard !view.isHidden, view.alpha > 0.01 else { return [] }
    let candidates = view.subviews.flatMap { verticalScrollViews(in: $0, window: window) }
    guard let scrollView = view as? UIScrollView,
          scrollView.window === window,
          scrollView.bounds.height > 0,
          scrollView.contentSize.height > scrollView.bounds.height + 1 else { return candidates }
    let visibleFrame = scrollView.convert(scrollView.bounds, to: window).intersection(window.bounds)
    guard !visibleFrame.isNull, !visibleFrame.isEmpty,
          let hitView = window.hitTest(CGPoint(x: visibleFrame.midX, y: visibleFrame.midY), with: nil),
          hitView === scrollView || hitView.isDescendant(of: scrollView) else { return candidates }
    return [scrollView] + candidates
  }

  @MainActor
  private func makeFrames() async throws -> [Frame] {
    let owner = ClassRoom.mocks[0]
    let member = ClassRoom.mockJoinable
    let aiQuestion = ClassAIQuestion.examples[0]
    let filter = ClassTopicFilter(categories: [.philosophy])
    var topic = ClassTopicFeature.State()
    topic.categories = [.philosophy]
    let aiBattle = try XCTUnwrap(ClassSettingFeature.State(aiQuestion: aiQuestion, filter: filter).aiBattle)
    let aiRoom = ClassRoom(
      id: 801,
      name: "AI 질문 토론 클래스",
      joinCode: "PKAI01",
      battle: aiBattle,
      deadline: owner.deadline,
      memberCount: 32,
      role: .member,
      status: .open,
      allowsAnonymousOpinion: false,
      requiresComment: false
    )
    var aiChatAlert = ClassAIChatFeature.State(room: aiRoom, battleID: -1_000_801, selectedOptionID: 1)
    aiChatAlert.isCompleted = true
    aiChatAlert.customAlert = .finalVote()
    let session = ClassMockChatSession()
    let battleID = await session.register(room: member)
    let preVoteSession = ClassMockChatSession()
    let preVoteBattleID = await preVoteSession.register(room: member)
    let battleAPI: any BattleInterface = session
    _ = try await battleAPI.createPerspective(
      battleId: battleID,
      content: "감정을 드러내는 방식은 사람마다 다를 수 있다고 생각합니다.",
      optionId: 1
    )
    let previewRepository = MockClassRepository(
      rooms: ClassRoom.mocks + [member, .mockClosedSociety],
      availableRooms: []
    )
    let ownerMembers = try await previewRepository.fetchMembers(roomID: owner.id)
    let memberMembers = try await previewRepository.fetchMembers(roomID: member.id)

    func classTab(_ screen: ClassCoordinator.ClassScreen.State) -> AnyView {
      let repository: MockClassRepository = if case let .myClasses(list) = screen {
        MockClassRepository(rooms: list.rooms, availableRooms: [])
      } else {
        previewRepository
      }
      var state = MainTabCoordinator.State(selectedTab: MainTabCoordinator.Tab.classroom.rawValue)
      state.classState.routes.push(screen)
      return AnyView(MainTabView(store: Store(initialState: state) {
        MainTabCoordinator()
          .dependency(\.classUseCase, repository)
          .dependency(\.classMockRepository, repository)
          .dependency(\.classMockChatSession, session)
          .dependency(\.classMockAudioPlayer, ClassMockAudioPlayer())
      }))
    }

    func loadedClassFrame(
      _ number: Int,
      _ title: String,
      _ slug: String,
      _ detail: String,
      _ screen: ClassCoordinator.ClassScreen.State
    ) -> Frame {
      var state = MainTabCoordinator.State(selectedTab: MainTabCoordinator.Tab.classroom.rawValue)
      state.classState.routes.push(screen)
      let store = Store(initialState: state) {
        MainTabCoordinator()
          .dependency(\.classUseCase, previewRepository)
          .dependency(\.classMockRepository, previewRepository)
          .dependency(\.classMockChatSession, session)
          .dependency(\.classMockAudioPlayer, ClassMockAudioPlayer())
      }
      let ready: @MainActor () -> Bool = {
        switch store.classState.routes.last?.screen {
        case let .report(value)?:
          return value.hasLoaded && !value.isLoading && !value.loadFailed && value.report != nil
        case let .ownerDashboard(value)?:
          return value.hasLoaded && !value.isLoading && !value.loadFailed
            && value.report != nil && value.metrics != nil
        default:
          return false
        }
      }
      return Frame(
        number: number,
        title: title,
        slug: slug,
        detail: detail,
        view: AnyView(MainTabView(store: store)),
        ready: ready
      )
    }

    func chatFrame(
      _ number: Int,
      _ title: String,
      _ slug: String,
      _ state: ChatCoordinator.State,
      session frameSession: ClassMockChatSession,
      battleID frameBattleID: Int
    ) -> Frame {
      let store = Store(initialState: state) {
        ChatCoordinator()
          .dependency(\.battleUseCase, frameSession)
          .dependency(\.perspectiveUseCase, frameSession)
          .dependency(\.commentUseCase, frameSession)
          .dependency(\.audioPlayer, ClassMockAudioPlayer())
          .dependency(\.analyticsUseCase, .testValue)
          .dependency(\.shareUseCase, .testValue)
      }
      let ready: @MainActor () -> Bool = {
        switch (number, store.routes.last?.screen) {
        case let (16, .preVote(value)?) where value.voteMode == .post:
          return value.battle != nil && !value.detailLoadFailed && !value.isCheckingParticipation
        case let (18, .preVote(value)?) where value.voteMode == .pre:
          return value.battle != nil && !value.detailLoadFailed && !value.isCheckingParticipation
        case let (17, .chatRoom(value)?):
          return value.scenario != nil && !value.scenarioLoadFailed
        case let (15, .comment(value)?):
          return !value.title.isEmpty && !value.isLoadingComments && !value.isLoadingStats
        default:
          return false
        }
      }
      return Frame(
        number: number,
        title: title,
        slug: slug,
        detail: "seeded member battle; async mock load",
        view: AnyView(ClassChatCoordinatorView(store: store, roomsByBattleID: [frameBattleID: member])),
        ready: ready
      )
    }

    var chatRoom = ChatCoordinator.State(battleId: battleID)
    chatRoom.routes = [.root(.chatRoom(.init(battleId: battleID)), embedInNavigationView: true)]

    var aiRecommend = ClassRecommendFeature.State(filter: filter, mode: .aiQuestions)
    aiRecommend.questions = ClassAIQuestion.examples
    aiRecommend.selectedQuestionId = aiQuestion.id
    var existingRecommend = ClassRecommendFeature.State(filter: filter)
    existingRecommend.battles = ClassBattleSummary.mocks
    existingRecommend.selectedBattleId = ClassBattleSummary.mocks[0].id
    var ownerList = MyClassFeature.State()
    ownerList.rooms = ClassRoom.mocks
    var memberList = MyClassFeature.State()
    memberList.rooms = memberRooms
    var ownerReport = ClassOwnerDashboardFeature.State(room: owner, instanceID: UUID())
    ownerReport.selectedTab = .report

    func frame(_ number: Int, _ title: String, _ slug: String, _ detail: String, _ view: AnyView?) -> Frame {
      Frame(number: number, title: title, slug: slug, detail: detail, view: view, ready: nil)
    }

    return [
      frame(
        1,
        "AI 질문 추천",
        "ai-recommend",
        "selected first AI question",
        AnyView(ClassRecommendView(store: Store(initialState: aiRecommend) { ClassRecommendFeature() }))
      ),
      frame(
        2,
        "AI 질문 설정",
        "ai-setting",
        "first AI question; empty class name",
        AnyView(ClassSettingView(store: Store(initialState: .init(aiQuestion: aiQuestion, filter: filter)) {
          ClassSettingFeature()
        }))
      ),
      frame(
        3,
        "홈",
        "home",
        "real Home tab; login and async data may limit content",
        AnyView(MainTabView(store: Store(initialState: .init()) { MainTabCoordinator() }))
      ),
      frame(
        4,
        "클래스 인트로",
        "intro",
        "real Class tab; intro hides tab bar",
        AnyView(MainTabView(store: Store(initialState: .init(selectedTab: MainTabCoordinator.Tab.classroom.rawValue)) {
          MainTabCoordinator()
            .dependency(\.classUseCase, previewRepository)
            .dependency(\.classMockRepository, previewRepository)
        }))
      ),
      frame(
        5,
        "시작 방식",
        "start-method",
        "existing content initially selected",
        AnyView(ClassStartMethodView(store: Store(initialState: .init()) { ClassStartMethodFeature() }))
      ),
      frame(
        6,
        "주제와 조건",
        "topic",
        "Figma category selection: philosophy",
        AnyView(ClassTopicView(store: Store(initialState: topic) { ClassTopicFeature() }))
      ),
      frame(
        7,
        "클래스 공유",
        "share",
        "owner mock room",
        AnyView(ClassShareView(store: Store(initialState: .init(room: owner)) { ClassShareFeature() }))
      ),
      frame(
        8,
        "기존 배틀 설정",
        "existing-setting",
        "first mock battle",
        AnyView(ClassSettingView(store: Store(initialState: .init(battle: ClassBattleSummary.mocks[0])) {
          ClassSettingFeature()
        }))
      ),
      frame(
        9,
        "기존 배틀 추천",
        "existing-recommend",
        "selected first mock battle",
        AnyView(ClassRecommendView(store: Store(initialState: existingRecommend) { ClassRecommendFeature() }))
      ),
      frame(
        10,
        "이름 입력",
        "join-name",
        "member room preview",
        AnyView(ClassJoinView(store: Store(initialState: .init(mode: .nickname, preview: member)) { ClassJoinFeature()
        }))
      ),
      frame(
        11,
        "코드 입력",
        "join-code",
        "empty code",
        AnyView(ClassJoinView(store: Store(initialState: .init(mode: .code)) { ClassJoinFeature() }))
      ),
      frame(
        12,
        "멤버 내 클래스",
        "member-classes",
        "Figma fixture: two open and one closed member room",
        classTab(.myClasses(memberList))
      ),
      frame(
        13,
        "멤버 클래스 상세",
        "member-detail",
        "open member room",
        classTab(.detail(.init(room: member)))
      ),
      frame(
        14,
        "멤버 목록",
        "member-list",
        "member room with mock members",
        classTab(.members(.init(
          room: member,
          members: memberMembers,
          currentMemberID: 2
        )))
      ),
      chatFrame(15, "댓글", "comment", .init(commentBattleId: battleID), session: session, battleID: battleID),
      chatFrame(
        16,
        "최종 투표",
        "final-vote",
        .init(route: .finalVote(battleId: battleID)),
        session: session,
        battleID: battleID
      ),
      chatFrame(17, "청취와 대화", "chat-room", chatRoom, session: session, battleID: battleID),
      chatFrame(
        18,
        "사전 투표",
        "pre-vote",
        .init(battleId: preVoteBattleID),
        session: preVoteSession,
        battleID: preVoteBattleID
      ),
      loadedClassFrame(
        19,
        "멤버 개인 리포트",
        "member-report",
        "member room summary tab",
        .report(.init(room: member))
      ),
      frame(
        20,
        "마감 배틀",
        "closed-battle",
        "closed member room",
        AnyView(ClassClosedBattleView(store: Store(initialState: .init(room: .mockClosedSociety)) {
          ClassClosedBattleFeature()
        }))
      ),
      frame(
        21,
        "운영자 내 클래스",
        "owner-classes",
        "three owner mock rooms",
        classTab(.myClasses(ownerList))
      ),
      frame(
        22,
        "운영자 클래스 상세",
        "owner-detail",
        "open owner room",
        classTab(.detail(.init(room: owner)))
      ),
      loadedClassFrame(
        23,
        "운영자 클래스 요약",
        "owner-dashboard",
        "loaded home metrics",
        .ownerDashboard(.init(room: owner))
      ),
      frame(
        24,
        "운영자 멤버 목록",
        "owner-members",
        "owner room with mock members",
        classTab(.members(.init(
          room: owner,
          members: ownerMembers,
          currentMemberID: 1
        )))
      ),
      loadedClassFrame(
        25,
        "운영자 내 리포트",
        "owner-report",
        "loaded report metrics",
        .ownerDashboard(ownerReport)
      ),
      frame(
        26,
        "최종 투표 안내",
        "final-vote-alert",
        "AI chat completed; final vote confirmation",
        AnyView(ClassAIChatView(store: Store(initialState: aiChatAlert) {
          ClassAIChatFeature().dependency(\.classAIChatUseCase, MockClassAIChatUseCase())
        }))
      ),
      frame(
        27,
        "AI 질문 대화",
        "ai-chat",
        "round one before Foundation Models response",
        AnyView(ClassAIChatView(store: Store(initialState: .init(
          room: aiRoom,
          battleID: -1_000_801,
          selectedOptionID: 1
        )) { ClassAIChatFeature().dependency(\.classAIChatUseCase, MockClassAIChatUseCase()) }))
      ),
      frame(
        28,
        "AI 질문 단일 투표",
        "ai-vote",
        "AI question mock room",
        AnyView(ClassAIVoteView(store: Store(initialState: .init(room: aiRoom, battleID: -1_000_801)) {
          ClassAIVoteFeature()
        }))
      ),
    ]
  }
}
