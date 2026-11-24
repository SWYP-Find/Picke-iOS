//
//  CommentFinalDesignTests.swift
//  PickeTests
//
//  Created by Picke on 10/15/26.
//

import BattleDomainInterface
import CommentDomainInterface
import ComposableArchitecture
import FeatureAssembly
@testable import Picke
import PerspectiveDomainInterface
import SwiftUI
import UIKit
import Vision
import XCTest

/// Opt-in captures of the mounted global comment and reply screens for design review.
final class CommentFinalDesignTests: XCTestCase {
  @MainActor
  func testReplyCannotSendMoreThan200Characters() async {
    var state = CommentReplyFeature.State(perspectiveId: 1)
    state.replyText = String(repeating: "가", count: 200)
    XCTAssertTrue(state.isSendEnabled)

    state.replyText.append("나")
    XCTAssertFalse(state.isSendEnabled)

    var parentEditingState = state
    parentEditingState.editingParent = true
    XCTAssertNil(parentEditingState.replyCharacterLimit)
    XCTAssertTrue(parentEditingState.isSendEnabled)

    var replyEditingState = state
    replyEditingState.editingCommentId = 1
    XCTAssertEqual(replyEditingState.replyCharacterLimit, 200)
    XCTAssertFalse(replyEditingState.isSendEnabled)

    replyEditingState.replyText = String(repeating: "가", count: 200) + "\n"
    XCTAssertFalse(replyEditingState.isSendEnabled)

    let store = TestStore(initialState: state) { CommentReplyFeature() }
    await store.send(.view(.sendTapped))
    XCTAssertEqual(store.state.replyText.count, 201)
  }

  @MainActor
  func testBeginningReplyEditClearsParentEditAndKeepsOverlongText() async {
    let original = String(repeating: "가", count: 201)
    let store = TestStore(initialState: CommentReplyFeature.State(perspectiveId: 1)) {
      CommentReplyFeature()
    }

    await store.send(.view(.parentMenu(.edit))) {
      $0.editingParent = true
      $0.replyText = $0.parentComment.content
    }
    await store.send(.view(.beginEditing(commentId: 7, content: original))) {
      $0.editingParent = false
      $0.editingCommentId = 7
      $0.replyText = original
    }
    XCTAssertEqual(store.state.replyText, original)
    XCTAssertFalse(store.state.isSendEnabled)
    await store.send(.view(.sendTapped))
    XCTAssertEqual(store.state.replyText, original)
  }

  @MainActor
  func testReplyEditTakesInputFocus() async throws {
    guard ProcessInfo.processInfo.environment["PICKE_CLASS_VISUAL_AUDIT"] == "1" else {
      throw XCTSkip("Set PICKE_CLASS_VISUAL_AUDIT=1 to verify reply input focus")
    }

    let session = ClassMockChatSession()
    let battleID = await session.register(room: .mockJoinable)
    let battleAPI: any BattleInterface = session
    _ = try await battleAPI.submitPreVote(battleId: battleID, optionId: 1)
    _ = try await battleAPI.submitPostVote(battleId: battleID, optionId: 1)
    let createdPerspective = try await battleAPI.createPerspective(
      battleId: battleID,
      content: "부모 의견입니다.",
      optionId: 1
    )
    let perspective = try XCTUnwrap(createdPerspective)
    let perspectiveAPI: any PerspectiveInterface = session
    _ = try await perspectiveAPI.createComment(
      perspectiveId: perspective.perspectiveId,
      content: "수정할 답글입니다."
    )

    let store = Store(initialState: CommentReplyFeature.State(
      perspectiveId: perspective.perspectiveId,
      parentComment: CommentItem(item: perspective, order: 0)
    )) {
      CommentReplyFeature()
        .dependency(\.perspectiveUseCase, session)
        .dependency(\.commentUseCase, session)
        .dependency(\.analyticsUseCase, .testValue)
    }
    let window = try makeWindow(rootView: CommentReplyView(store: store))
    defer { window.isHidden = true }
    try await waitFor("reply loaded for focus") {
      !store.isLoadingDetail && !store.isLoadingReplies && !store.replies.isEmpty
    }

    let reply = try XCTUnwrap(store.replies.first)
    store.send(.view(.replyMenu(id: reply.id, action: .edit)))
    try await waitFor("reply edit first responder") { hasFocusedInput(in: window) }

    window.endEditing(true)
    try await waitFor("reply focus released") { !hasFocusedInput(in: window) }
    store.send(.view(.parentMenu(.edit)))
    try await waitFor("parent edit first responder") { hasFocusedInput(in: window) }
    XCTAssertTrue(store.editingParent)

    window.endEditing(true)
    try await waitFor("parent focus released") { !hasFocusedInput(in: window) }
    store.send(.view(.replyMenu(id: reply.id, action: .edit)))
    try await waitFor("reply focus after parent edit") { hasFocusedInput(in: window) }
    XCTAssertFalse(store.editingParent)
  }

  @MainActor
  func testGlobalCommentAndReplyCapture() async throws {
    guard ProcessInfo.processInfo.environment["PICKE_CLASS_VISUAL_AUDIT"] == "1" else {
      throw XCTSkip("Set PICKE_CLASS_VISUAL_AUDIT=1 to capture comment screens")
    }

    let session = ClassMockChatSession()
    let battleID = await session.register(room: .mockJoinable)
    let emptyStore = makeCommentStore(battleID: battleID, session: session)
    let emptyWindow = try makeWindow(rootView: CommentView(store: emptyStore))
    defer { emptyWindow.isHidden = true }
    try await waitFor("empty comment loaded") {
      !emptyStore.title.isEmpty && !emptyStore.isLoadingStats && !emptyStore.isLoadingComments
    }
    XCTAssertTrue(emptyStore.comments.isEmpty)
    XCTAssertFalse(emptyStore.isComposerExpanded)
    XCTAssertTrue(hasVisibleInput(in: emptyWindow), "The compact composer must be mounted on the empty screen")
    try await capture(emptyWindow, name: "comment-empty")
    emptyWindow.isHidden = true

    let longParent = (1 ... 5).map {
      "\($0)번째 생각입니다. 서로 다른 입장의 근거를 함께 살펴보고 싶어요."
    }.joined(separator: "\n")
    let battleAPI: any BattleInterface = session
    _ = try await battleAPI.submitPreVote(battleId: battleID, optionId: 1)
    _ = try await battleAPI.submitPostVote(battleId: battleID, optionId: 1)
    let createdPerspective = try await battleAPI.createPerspective(
      battleId: battleID,
      content: longParent,
      optionId: 1
    )
    let perspective = try XCTUnwrap(createdPerspective)
    let longReply = (1 ... 8).map {
      "\($0)번째 근거를 비교하며 충분한 설명인지 다시 살펴봅니다."
    }.joined(separator: "\n")
    let replyTexts = [
      "첫 번째 답글입니다. 부모 글에서 나온 주장에 동의합니다.",
      longReply,
      "세 번째 답글입니다.",
    ]
    let perspectiveAPI: any PerspectiveInterface = session
    for text in replyTexts {
      _ = try await perspectiveAPI.createComment(perspectiveId: perspective.perspectiveId, content: text)
    }

    let commentStore = makeCommentStore(battleID: battleID, session: session)
    let commentWindow = try makeWindow(rootView: CommentView(store: commentStore))
    defer { commentWindow.isHidden = true }
    try await waitFor("populated comment loaded") {
      !commentStore.title.isEmpty && !commentStore.isLoadingStats && !commentStore.isLoadingComments
        && commentStore.comments.contains { $0.isMine && $0.replyCount == replyTexts.count }
    }
    XCTAssertFalse(commentStore.isComposerExpanded)
    XCTAssertTrue(hasVisibleInput(in: commentWindow), "The compact composer must be mounted with comments")
    try await capture(commentWindow, name: "comment-populated")

    commentStore.send(.binding(.set(\.commentText, "작성 중인 새 의견입니다.")))
    XCTAssertTrue(commentStore.isSendEnabled)
    try await capture(commentWindow, name: "comment-draft")

    let parent = try XCTUnwrap(commentStore.comments.first { $0.isMine })
    commentStore.send(.view(.commentMenu(id: parent.id, action: .more)))
    XCTAssertEqual(commentStore.menuTargetCommentID, parent.id)
    let commentScroll = try XCTUnwrap(verticalScrollView(in: commentWindow))
    scrollToBottom(commentScroll)
    let menuImage = try await capture(commentWindow, name: "comment-last-row-menu")
    try assertMenuLabels(["수정", "삭제"], visibleIn: commentScroll, window: commentWindow, image: menuImage)
    commentStore.send(.view(.commentMenu(id: parent.id, action: .edit)))
    XCTAssertEqual(commentStore.editingPerspectiveId, parent.perspectiveId)
    XCTAssertEqual(commentStore.commentText, longParent)
    try await capture(commentWindow, name: "comment-edit")
    commentWindow.isHidden = true

    let replyStore = Store(initialState: CommentReplyFeature.State(
      perspectiveId: perspective.perspectiveId,
      parentComment: parent
    )) {
      CommentReplyFeature()
        .dependency(\.perspectiveUseCase, session)
        .dependency(\.commentUseCase, session)
        .dependency(\.analyticsUseCase, .testValue)
    }
    let replyWindow = try makeWindow(rootView: CommentReplyView(store: replyStore))
    defer { replyWindow.isHidden = true }
    try await waitFor("parent and replies loaded") {
      !replyStore.isLoadingDetail && !replyStore.isLoadingReplies
        && replyStore.parentComment.content == longParent
        && replyStore.replies.count == replyTexts.count
    }
    XCTAssertTrue(hasVisibleInput(in: replyWindow), "The reply composer must be mounted")
    try await capture(replyWindow, name: "reply-parent-top")
    let replyScroll = try XCTUnwrap(verticalScrollView(in: replyWindow))
    scrollToBottom(replyScroll)
    try await capture(replyWindow, name: "reply-list-bottom")

    replyStore.send(.binding(.set(\.replyText, "답글을 작성하고 있어요.")))
    XCTAssertTrue(replyStore.isSendEnabled)
    try await capture(replyWindow, name: "reply-draft")
    let middleReply = replyStore.replies[1]
    scrollToBottom(replyScroll)
    let middleOffset = replyScroll.contentOffset.y
    replyStore.send(.view(.replyMenu(id: middleReply.id, action: .more)))
    XCTAssertEqual(replyStore.menuTargetReplyId, middleReply.id)
    try await Task.sleep(for: .milliseconds(350))
    XCTAssertEqual(replyScroll.contentOffset.y, middleOffset, accuracy: 1)
    let middleMenuImage = try await capture(replyWindow, name: "reply-middle-row-menu")
    try assertMenuLabels(["수정", "삭제"], visibleIn: replyScroll, window: replyWindow, image: middleMenuImage)
    replyStore.send(.view(.replyMenu(id: middleReply.id, action: .more)))
    let lastReply = try XCTUnwrap(replyStore.replies.last)
    scrollToTop(replyScroll)
    XCTAssertGreaterThan(replyScroll.contentSize.height, replyScroll.bounds.height)
    let topOffset = -replyScroll.adjustedContentInset.top
    XCTAssertEqual(replyScroll.contentOffset.y, topOffset, accuracy: 1)
    replyStore.send(.view(.replyMenu(id: lastReply.id, action: .more)))
    XCTAssertEqual(replyStore.menuTargetReplyId, lastReply.id)
    try await Task.sleep(for: .milliseconds(350))
    XCTAssertGreaterThan(replyScroll.contentOffset.y, topOffset + 1)
    let replyMenuImage = try await capture(replyWindow, name: "reply-last-row-menu")
    try assertMenuLabels(["수정", "삭제"], visibleIn: replyScroll, window: replyWindow, image: replyMenuImage)
    replyStore.send(.view(.replyMenu(id: lastReply.id, action: .edit)))
    XCTAssertEqual(replyStore.editingCommentId, lastReply.commentId)
    XCTAssertEqual(replyStore.replyText, lastReply.content)
    try await waitFor("reply edit focus") { hasFocusedInput(in: replyWindow) }
    try await capture(replyWindow, name: "reply-edit")

    replyWindow.endEditing(true)
    try await waitFor("reply focus released before parent menu") { !hasFocusedInput(in: replyWindow) }
    scrollToBottom(replyScroll)
    let parentBottomOffset = replyScroll.contentOffset.y
    XCTAssertGreaterThan(parentBottomOffset, topOffset + 1)
    replyStore.send(.view(.parentMenu(.more)))
    XCTAssertTrue(replyStore.parentMenuOpen)
    try await Task.sleep(for: .milliseconds(350))
    let parentMenuImage = try await capture(replyWindow, name: "reply-parent-menu")
    try assertMenuLabels(["수정", "삭제"], visibleIn: replyScroll, window: replyWindow, image: parentMenuImage)
    replyStore.send(.view(.parentMenu(.edit)))
    try await waitFor("parent edit focus") { hasFocusedInput(in: replyWindow) }
    XCTAssertTrue(replyStore.editingParent)

    replyWindow.endEditing(true)
    try await waitFor("parent focus released before reply edit") { !hasFocusedInput(in: replyWindow) }
    replyStore.send(.view(.replyMenu(id: lastReply.id, action: .edit)))
    try await waitFor("reply focus after parent edit") { hasFocusedInput(in: replyWindow) }
    XCTAssertFalse(replyStore.editingParent)
  }

  @MainActor
  func testParentMenuScrollsIntoViewFromBelowReplies() async throws {
    guard ProcessInfo.processInfo.environment["PICKE_CLASS_VISUAL_AUDIT"] == "1" else {
      throw XCTSkip("Set PICKE_CLASS_VISUAL_AUDIT=1 to verify the off-screen parent menu")
    }

    let session = ClassMockChatSession()
    let battleID = await session.register(room: .mockJoinable)
    let battleAPI: any BattleInterface = session
    _ = try await battleAPI.submitPreVote(battleId: battleID, optionId: 1)
    _ = try await battleAPI.submitPostVote(battleId: battleID, optionId: 1)
    let createdPerspective = try await battleAPI.createPerspective(
      battleId: battleID,
      content: "화면 위쪽에 놓일 부모 의견입니다.",
      optionId: 1
    )
    let perspective = try XCTUnwrap(createdPerspective)
    let perspectiveAPI: any PerspectiveInterface = session
    for index in 1 ... 12 {
      _ = try await perspectiveAPI.createComment(
        perspectiveId: perspective.perspectiveId,
        content: "\(index)번째 답글입니다. 부모 의견 아래로 목록을 충분히 길게 만듭니다."
      )
    }

    let store = Store(initialState: CommentReplyFeature.State(
      perspectiveId: perspective.perspectiveId,
      parentComment: CommentItem(item: perspective, order: 0)
    )) {
      CommentReplyFeature()
        .dependency(\.perspectiveUseCase, session)
        .dependency(\.commentUseCase, session)
        .dependency(\.analyticsUseCase, .testValue)
    }
    let window = try makeWindow(rootView: CommentReplyView(store: store))
    defer { window.isHidden = true }
    try await waitFor("long reply list loaded") {
      !store.isLoadingDetail && !store.isLoadingReplies && store.replies.count == 12
    }

    let scroll = try XCTUnwrap(verticalScrollView(in: window))
    scrollToBottom(scroll)
    let bottomOffset = scroll.contentOffset.y
    XCTAssertGreaterThan(bottomOffset, 500, "The parent menu must begin outside the viewport")

    store.send(.view(.parentMenu(.more)))
    XCTAssertTrue(store.parentMenuOpen)
    try await Task.sleep(for: .milliseconds(350))
    XCTAssertLessThan(scroll.contentOffset.y, bottomOffset - 1)
    let image = try await capture(window, name: "reply-parent-menu-from-bottom")
    try assertMenuLabels(["수정", "삭제"], visibleIn: scroll, window: window, image: image)
  }

  @MainActor
  private func makeCommentStore(
    battleID: Int,
    session: ClassMockChatSession
  ) -> StoreOf<CommentFeature> {
    Store(initialState: CommentFeature.State(battleId: battleID)) {
      CommentFeature()
        .dependency(\.battleUseCase, session)
        .dependency(\.perspectiveUseCase, session)
        .dependency(\.commentUseCase, session)
        .dependency(\.analyticsUseCase, .testValue)
    }
  }

  @MainActor
  private func makeWindow<Content: View>(rootView: Content) throws -> UIWindow {
    let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
    let window = UIWindow(windowScene: scene)
    window.frame = scene.coordinateSpace.bounds
    window.rootViewController = UIHostingController(rootView: rootView.transaction { transaction in
      transaction.animation = nil
      transaction.disablesAnimations = true
    })
    window.makeKeyAndVisible()
    return window
  }

  @MainActor
  private func waitFor(
    _ description: String,
    until predicate: () -> Bool
  ) async throws {
    for _ in 0 ..< 100 {
      if predicate() { return }
      try await Task.sleep(for: .milliseconds(50))
    }
    XCTFail("Comment audit did not reach: \(description)")
    throw AuditError.contentNotReady
  }

  @MainActor
  private func hasVisibleInput(in window: UIWindow) -> Bool {
    func containsInput(_ view: UIView) -> Bool {
      if (view is UITextField || view is UITextView), view.window === window,
         !view.isHidden, view.alpha > 0.01
      {
        let frame = view.convert(view.bounds, to: window)
        return frame.width > 0 && frame.height > 0 && frame.intersects(window.bounds)
      }
      return view.subviews.contains(where: containsInput)
    }
    window.layoutIfNeeded()
    return window.rootViewController.map { containsInput($0.view) } ?? false
  }

  @MainActor
  private func hasFocusedInput(in window: UIWindow) -> Bool {
    func containsFocusedInput(_ view: UIView) -> Bool {
      if (view is UITextField || view is UITextView), view.window === window, view.isFirstResponder {
        return true
      }
      return view.subviews.contains(where: containsFocusedInput)
    }
    window.layoutIfNeeded()
    return window.rootViewController.map { containsFocusedInput($0.view) } ?? false
  }

  @MainActor
  private func verticalScrollView(in window: UIWindow) -> UIScrollView? {
    func all(in view: UIView) -> [UIScrollView] {
      let children = view.subviews.flatMap { all(in: $0) }
      guard let scroll = view as? UIScrollView,
            !(scroll is UITextView),
            scroll.window === window, scroll.bounds.height > 0,
            !scroll.isHidden, scroll.alpha > 0.01
      else { return children }
      return [scroll] + children
    }
    guard let root = window.rootViewController?.view else { return nil }
    return all(in: root).max { $0.bounds.height < $1.bounds.height }
  }

  @MainActor
  private func scrollToBottom(_ scroll: UIScrollView) {
    let offset = max(-scroll.adjustedContentInset.top,
                     scroll.contentSize.height - scroll.bounds.height + scroll.adjustedContentInset.bottom)
    scroll.setContentOffset(CGPoint(x: scroll.contentOffset.x, y: offset), animated: false)
    scroll.layoutIfNeeded()
  }

  @MainActor
  private func scrollToTop(_ scroll: UIScrollView) {
    scroll.setContentOffset(CGPoint(x: scroll.contentOffset.x, y: -scroll.adjustedContentInset.top), animated: false)
    scroll.layoutIfNeeded()
  }

  @MainActor
  @discardableResult
  private func capture(
    _ window: UIWindow,
    name: String
  ) async throws -> UIImage {
    // Static captures suppress SwiftUI transitions; still allow pending layout updates to render.
    window.layoutIfNeeded()
    try await Task.sleep(for: .milliseconds(300))
    window.layoutIfNeeded()
    CATransaction.flush()
    var didRenderHierarchy = false
    let image = UIGraphicsImageRenderer(bounds: window.bounds).image { _ in
      didRenderHierarchy = window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
    }
    XCTAssertTrue(didRenderHierarchy, "The full comment audit hierarchy must render before capture")
    let directory = try FileManager.default.url(
      for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true
    ).appendingPathComponent("CommentFinalAudit", isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    try XCTUnwrap(image.pngData()).write(to: directory.appendingPathComponent(name + ".png"))
    let attachment = XCTAttachment(image: image)
    attachment.name = name
    attachment.lifetime = .keepAlways
    add(attachment)
    return image
  }

  @MainActor
  private func assertMenuLabels(
    _ labels: [String],
    visibleIn scroll: UIScrollView,
    window: UIWindow,
    image: UIImage
  ) throws {
    let request = VNRecognizeTextRequest()
    request.recognitionLevel = .accurate
    request.recognitionLanguages = ["ko-KR", "en-US"]
    request.usesLanguageCorrection = false
    // Read the trailing menu separately so text behind the overlay cannot merge
    // with its short labels during line recognition.
    let menuRegion = CGRect(x: 0.76, y: 0, width: 0.24, height: 1)
    request.regionOfInterest = menuRegion
    try VNImageRequestHandler(cgImage: XCTUnwrap(image.cgImage)).perform([request])
    let viewport = scroll.convert(scroll.bounds, to: window).intersection(window.bounds)
    var observedBounds: [CGRect] = []
    for label in labels {
      let observation = (request.results ?? []).first(where: {
        $0.topCandidates(5).contains {
          $0.string.replacingOccurrences(of: " ", with: "").contains(label)
        }
      })
      XCTAssertNotNil(observation, "Menu label \(label) must be readable in the capture")
      guard let observation else { continue }
      let bounds = observation.boundingBox
      let labelFrame = CGRect(
        x: (menuRegion.minX + bounds.minX * menuRegion.width) * window.bounds.width,
        y: (1 - (menuRegion.minY + bounds.maxY * menuRegion.height)) * window.bounds.height,
        width: bounds.width * menuRegion.width * window.bounds.width,
        height: bounds.height * menuRegion.height * window.bounds.height
      )
      XCTAssertTrue(viewport.contains(labelFrame), "Menu label \(label) is outside the visible comment list")
      observedBounds.append(labelFrame)
    }
    if observedBounds.count == labels.count {
      XCTAssertEqual(
        Set(observedBounds.map { $0.midY.rounded() }).count,
        labels.count,
        "Menu labels must occupy separate visible buttons"
      )
    }
  }

  private enum AuditError: Error {
    case contentNotReady
  }
}
