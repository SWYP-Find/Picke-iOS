//
//  ClassShareAuditView.swift
//  PickeClassAuditHost
//
//  Created by Picke on 10/17/26.
//

import ComposableArchitecture
import DomainAssembly
import FeatureAssembly
import SwiftUI

/// A retained, text-only share fixture in the opt-in UI audit app.
struct ClassShareAuditView: View {
  @State private var fixture: ClassShareAuditFixture?

  var body: some View {
    ZStack {
      content()
    }
    .task { await prepareFixture() }
  }
}

private extension ClassShareAuditView {
  @ViewBuilder
  func content() -> some View {
    if let fixture {
      ClassShareAuditContentView(
        store: fixture.store,
        room: fixture.room
      )
    } else {
      ProgressView()
    }
  }

  @MainActor
  func prepareFixture() async {
    guard fixture == nil else { return }
    let room = ClassRoom.mockJoinable
    let session = ClassMockChatSession()
    let battleID = await session.register(room: room)
    guard !Task.isCancelled, fixture == nil else { return }
    let store = withDependencies {
      $0.context = .test
    } operation: {
      Store(initialState: PreVoteFeature.State(battleId: battleID, voteMode: .post)) {
        PreVoteFeature()
          .dependency(\.battleUseCase, session)
          .dependency(\.perspectiveUseCase, session)
          .dependency(\.shareUseCase, .testValue)
          .dependency(\.analyticsUseCase, .testValue)
      }
    }
    fixture = ClassShareAuditFixture(store: store, room: room)
  }
}

private struct ClassShareAuditFixture {
  let store: StoreOf<PreVoteFeature>
  let room: ClassRoom
}

private struct ClassShareAuditContentView: View {
  @Bindable private var store: StoreOf<PreVoteFeature>
  private let room: ClassRoom

  init(
    store: StoreOf<PreVoteFeature>,
    room: ClassRoom
  ) {
    self.store = store
    self.room = room
  }

  var body: some View {
    ClassVoteView(store: store, room: room)
  }
}
