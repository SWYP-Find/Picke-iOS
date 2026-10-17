//
//  ClassCreationDeadlineAuditView.swift
//  PickeClassAuditHost
//
//  Created by Picke on 10/17/26.
//

import ComposableArchitecture
import DomainAssembly
import FeatureAssembly
import Foundation
import PickeAnalyticsInterface
import PickeCoreUtility
import PickeDesignKit
import SwiftUI
import TCAFlow

/// Mounts the real creation setting route; diagnostics only observe coordinator state.
struct ClassCreationDeadlineAuditView: View {
  @Bindable private var store: StoreOf<ClassCoordinator>
  private let scenario: String

  init(scenario: String) {
    self.scenario = scenario
    let calendar = AppDateFormat.calendar
    let now = calendar.date(from: DateComponents(year: 2030, month: 1, day: 15, hour: 10, minute: 30))!
    let deadline = calendar.date(from: DateComponents(year: 2030, month: 1, day: 18, hour: 12, minute: 40))!
    let instanceID = UUID(uuidString: "00000000-0000-0000-0000-000000000123")!
    var setting: ClassSettingFeature.State
    if scenario == "ai" {
      setting = .init(aiQuestion: .examples[0], filter: .init(), deadline: deadline, instanceID: instanceID)
    } else {
      setting = .init(battle: ClassRoom.mockJoinable.battle, deadline: deadline, instanceID: instanceID)
    }
    setting.name = "마감일 상호작용 검증 클래스"
    setting.requiresComment = true
    setting.ownerParticipates = true

    var state = ClassCoordinator.State()
    state.routes.push(.setting(setting))
    let repository = MockClassRepository(rooms: [], availableRooms: [])
    let session = ClassMockChatSession()
    store = withDependencies {
      $0.context = .test
      $0.uuid = .incrementing
      $0.date.now = now
    } operation: {
      Store(initialState: state) {
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
    .environment(\.locale, Locale(identifier: "ko_KR"))
  }
}

private extension ClassCreationDeadlineAuditView {
  var diagnostics: some View {
    Text("Class creation deadline UI audit")
      .pretendardFont(family: .Regular, size: 10)
      .accessibilityIdentifier("audit-class-creation-deadline-state")
      .accessibilityValue(diagnosticValue)
      .allowsHitTesting(false)
  }

  var diagnosticValue: String {
    var values: [String: Any] = [
      "scenario": scenario,
      "routeCount": store.routes.count,
      "routeKind": "other",
      "isPush": store.routes.last?.isPush ?? false,
      "hasDeadlineSelection": store.deadlineSelection != nil,
      "hasDeadlineEdit": store.deadlineEdit != nil,
      "selectionDraft": canonical(store.deadlineSelection?.draftDeadline),
      "selectionSourceInstance": store.deadlineSelection?.settingInstanceID.uuidString ?? "",
      "settingInstance": "",
      "name": "",
      "contentID": 0,
      "contentKind": "",
      "deadline": "",
      "deadlineText": "",
      "isDeadlineEnabled": false,
      "requiresComment": false,
      "ownerParticipates": false,
    ]
    if case let .setting(setting)? = store.routes.last?.screen {
      values["routeKind"] = "setting"
      values["settingInstance"] = setting.instanceID.uuidString
      values["name"] = setting.name
      values["contentID"] = setting.aiQuestion?.id ?? setting.battle?.id ?? 0
      values["contentKind"] = setting.aiQuestion == nil ? "regular" : "ai"
      values["deadline"] = canonical(setting.deadline)
      values["deadlineText"] = setting.deadlineText
      values["isDeadlineEnabled"] = setting.isDeadlineEnabled
      values["requiresComment"] = setting.requiresComment
      values["ownerParticipates"] = setting.ownerParticipates
    }
    guard let data = try? JSONSerialization.data(withJSONObject: values, options: [.sortedKeys]),
          let json = String(data: data, encoding: .utf8) else { return "{}" }
    return json
  }

  func canonical(_ date: Date?) -> String {
    guard let date else { return "" }
    let parts = AppDateFormat.calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
    return String(
      format: "%04d-%02d-%02dT%02d:%02d",
      parts.year ?? 0, parts.month ?? 0, parts.day ?? 0, parts.hour ?? 0, parts.minute ?? 0
    )
  }
}
