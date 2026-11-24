//
//  CommentInteractionAuditView.swift
//  PickeClassAuditHost
//
//  Created by Picke on 10/17/26.
//

import BattleDomainInterface
import ComposableArchitecture
import DomainAssembly
import FeatureAssembly
import PickeAnalyticsInterface
import PickeDesignKit
import SwiftUI
import TCAFlow

/// Opt-in fixture that keeps the real chat coordinator and its actor session alive.
struct CommentInteractionAuditView: View {
  let scenario: String
  @State private var fixture: CommentInteractionFixture?
  @State private var error: String?

  var body: some View {
    ZStack {
      content()
    }
    .task { await prepareFixture() }
  }
}

private extension CommentInteractionAuditView {
  @ViewBuilder
  func content() -> some View {
    if let fixture {
      CommentInteractionAuditContentView(fixture: fixture)
    } else if let error {
      Text(error)
        .accessibilityIdentifier("audit-fixture-error")
    } else {
      ProgressView()
    }
  }

  @MainActor
  func prepareFixture() async {
    guard fixture == nil, error == nil else { return }
    let room = ClassRoom.mockJoinable
    let session = ClassMockChatSession()
    let battleID = await session.register(room: room)
    do {
      let battle: any BattleInterface = session
      _ = try await battle.submitPreVote(battleId: battleID, optionId: 1)
      _ = try await battle.submitPostVote(battleId: battleID, optionId: 1)
      guard !Task.isCancelled, fixture == nil else { return }
      let store = withDependencies {
        $0.context = .test
      } operation: {
        Store(initialState: ChatCoordinator.State(commentBattleId: battleID)) {
          ChatCoordinator()
            .dependency(\.battleUseCase, session)
            .dependency(\.perspectiveUseCase, session)
            .dependency(\.commentUseCase, session)
            .dependency(\.analyticsUseCase, .testValue)
        }
      }
      fixture = CommentInteractionFixture(
        scenario: scenario,
        room: room,
        battleID: battleID,
        store: store
      )
    } catch {
      self.error = "Comment fixture setup failed: \(error.localizedDescription)"
    }
  }
}

private struct CommentInteractionFixture {
  let scenario: String
  let room: ClassRoom
  let battleID: Int
  let store: StoreOf<ChatCoordinator>
}

private struct CommentInteractionAuditContentView: View {
  @Bindable private var store: StoreOf<ChatCoordinator>
  private let fixture: CommentInteractionFixture

  init(fixture: CommentInteractionFixture) {
    self.fixture = fixture
    store = fixture.store
  }

  var body: some View {
    ZStack(alignment: .topLeading) {
      coordinator()
      diagnostics
    }
  }
}

private extension CommentInteractionAuditContentView {
  @ViewBuilder
  func coordinator() -> some View {
    if fixture.scenario == "class" {
      ClassChatCoordinatorView(
        store: store,
        roomsByBattleID: [fixture.battleID: fixture.room],
        onOpenReport: { _ in }
      )
    } else {
      ChatCoordinatorView(store: store)
    }
  }

  var diagnostics: some View {
    Text("Comment UI audit")
      .pretendardFont(family: .Regular, size: 10)
      .foregroundStyle(.clear)
      .accessibilityIdentifier("audit-comment-state")
      .accessibilityValue(diagnosticValue)
      .allowsHitTesting(false)
  }

  var diagnosticValue: String {
    guard let route = store.routes.last else { return "{}" }
    var values: [String: Any] = [
      "scenario": fixture.scenario,
      "routeCount": store.routes.count,
      "routeKind": route.isPush ? "push" : (route.isPresented ? "presented" : "root"),
      "commentText": "",
      "replyText": "",
      "perspectiveID": NSNull(),
      "parentContent": "",
      "commentContents": [String](),
      "replyContents": [String](),
      "replyCount": 0,
      "selectedFilter": "",
      "isReady": false,
    ]
    switch route.screen {
    case let .comment(comment):
      values["routeKind"] = route.isPush ? "comment-push" : "comment"
      values["isReady"] = !comment.isLoadingStats && !comment.isLoadingComments && !comment.title.isEmpty
      values["commentText"] = comment.commentText
      values["perspectiveID"] = comment.perspectiveId.map { $0 as Any } ?? NSNull()
      values["commentContents"] = comment.comments.map(\.content)
      values["selectedFilter"] = String(describing: comment.selectedFilter)
    case let .commentReply(reply):
      values["routeKind"] = route.isPush ? "reply-push" : "reply-presented"
      values["isReady"] = !reply.isLoadingDetail && !reply.isLoadingReplies && !reply.parentComment.content.isEmpty
      values["replyText"] = reply.replyText
      values["perspectiveID"] = reply.perspectiveId
      values["parentContent"] = reply.parentComment.content
      values["replyContents"] = reply.replies.map(\.content)
      values["replyCount"] = reply.replies.count
    default:
      break
    }
    guard let data = try? JSONSerialization.data(withJSONObject: values, options: [.sortedKeys]),
          let json = String(data: data, encoding: .utf8) else { return "{}" }
    return json
  }
}
