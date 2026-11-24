//
//  ClassJoinInteractionAuditView.swift
//  PickeClassAuditHost
//
//  Created by Picke on 10/17/26.
//

import ComposableArchitecture
import DomainAssembly
import FeatureAssembly
import Foundation
import PickeAnalyticsInterface
import PickeDesignKit
import SwiftUI
import TCAFlow

/// Starts at the real introduction and exposes only read-only route diagnostics.
struct ClassJoinInteractionAuditView: View {
  @Bindable private var store: StoreOf<ClassCoordinator>
  private let repository: MockClassRepository
  private let session: ClassMockChatSession

  init() {
    let repository = MockClassRepository(rooms: [], availableRooms: [.mockJoinable])
    let session = ClassMockChatSession()
    let now = Date()
    self.repository = repository
    self.session = session
    store = withDependencies {
      $0.context = .test
      $0.uuid = .incrementing
      $0.date.now = now
    } operation: {
      Store(initialState: ClassCoordinator.State()) {
        ClassCoordinator()
          .dependency(\.classUseCase, repository)
          .dependency(\.classMockRepository, repository)
          .dependency(\.classMockChatSession, session)
          .dependency(\.analyticsUseCase, .testValue)
      }
    }
  }

  var body: some View {
    ZStack(alignment: .topLeading) {
      ClassCoordinatorView(store: store)
      diagnostics
    }
  }
}

private extension ClassJoinInteractionAuditView {
  var diagnostics: some View {
    Text("Class join UI audit")
      .pretendardFont(family: .Regular, size: 10)
      .accessibilityIdentifier("audit-class-join-state")
      .accessibilityValue(diagnosticValue)
      .allowsHitTesting(false)
  }

  var diagnosticValue: String {
    let routes = store.routes.map { route in
      [
        "kind": screenKind(route.screen),
        "isPush": route.isPush,
        "isPresented": route.isPresented,
      ] as [String: Any]
    }
    var values: [String: Any] = [
      "routeCount": store.routes.count,
      "routes": routes,
      "lastRouteKind": store.routes.last.map { screenKind($0.screen) } ?? "none",
      "isPush": store.routes.last?.isPush ?? false,
      "lastMode": "",
      "code": "",
      "nickname": "",
      "previewID": NSNull(),
      "detailRoomID": NSNull(),
      "memberCount": 0,
      "roomRole": "",
      "isLoading": false,
      "errorMessage": NSNull(),
      "nicknameErrorMessage": NSNull(),
      "nicknameValidationMessage": NSNull(),
      "hasDeadlineEdit": store.deadlineEdit != nil,
      "hasDeadlineSelection": store.deadlineSelection != nil,
      "hasDetailModal": false,
      "hasDetailAlert": false,
      "pendingJoinCleared": store.pendingJoinID == nil,
    ]
    for route in store.routes {
      if case let .detail(detail) = route.screen {
        values["hasDetailModal"] = detail.modal != nil
        values["hasDetailAlert"] = detail.customAlert != nil
      }
    }
    switch store.routes.last?.screen {
    case let .join(join)?:
      values["lastMode"] = String(describing: join.mode)
      values["code"] = join.joinCode
      values["nickname"] = join.nickname
      values["previewID"] = join.preview.map { $0.id as Any } ?? NSNull()
      values["isLoading"] = join.isLoading
      values["errorMessage"] = join.errorMessage.map { $0 as Any } ?? NSNull()
      values["nicknameErrorMessage"] = join.nicknameErrorMessage.map { $0 as Any } ?? NSNull()
      values["nicknameValidationMessage"] = join.nicknameValidationMessage.map { $0 as Any } ?? NSNull()
    case let .detail(detail)?:
      values["detailRoomID"] = detail.room.id
      values["memberCount"] = detail.room.memberCount
      values["roomRole"] = String(describing: detail.room.role)
      values["isLoading"] = detail.isLoading
    default:
      break
    }
    guard let data = try? JSONSerialization.data(withJSONObject: values, options: [.sortedKeys]),
          let json = String(data: data, encoding: .utf8) else { return "{}" }
    return json
  }

  func screenKind(_ screen: ClassCoordinator.ClassScreen.State) -> String {
    switch screen {
    case .intro: return "intro"
    case .join: return "join"
    case .detail: return "detail"
    default: return "other"
    }
  }
}
