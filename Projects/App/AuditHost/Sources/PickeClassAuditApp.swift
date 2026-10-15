//
//  PickeClassAuditApp.swift
//  PickeClassAuditHost
//
//  Created by Picke on 10/15/26.
//

import ComposableArchitecture
import DomainAssembly
import FeatureAssembly
import PickeCoreUtility
import PickeDesignKit
import SwiftUI
import TCAFlow

/// This entry point belongs only to the opt-in audit target, never to Picke.
@main
struct PickeClassAuditApp: App {
  init() {
    PretendardFontFamily.registerFonts()
  }

  var body: some Scene {
    WindowGroup {
      if let scenario = ProcessInfo.processInfo.environment["PICKE_MEMBER_SCENARIO"],
         ["owner-remove", "member-leave"].contains(scenario) {
        MemberAuditView(scenario: scenario)
      } else if let scenario = ProcessInfo.processInfo.environment["PICKE_DEADLINE_SCENARIO"],
         ["normal", "minimum", "cycle"].contains(scenario) {
        DeadlineAuditView(scenario: scenario)
      } else {
        Text("Unknown deadline audit scenario")
          .accessibilityIdentifier("audit-fixture-error")
      }
    }
  }
}

private struct DeadlineAuditView: View {
  @Bindable private var store: StoreOf<ClassCoordinator>
  private let repository: MockClassRepository
  private let room: ClassRoom
  @State private var hasOpened = false
  @State private var persisted: Date?
  @State private var failed = false

  init(scenario: String) {
    let calendar = AppDateFormat.calendar
    let now = calendar.date(from: DateComponents(year: 2030, month: 1, day: 15, hour: 10, minute: 30))!
    let deadline: Date
    switch scenario {
    case "minimum":
      deadline = now.addingTimeInterval(60)
    case "cycle":
      deadline = calendar.date(from: DateComponents(year: 2030, month: 1, day: 18, hour: 23, minute: 59))!
    default:
      deadline = calendar.date(from: DateComponents(year: 2030, month: 1, day: 18, hour: 12, minute: 40))!
    }
    let room = ClassRoom(
      id: 1,
      name: "마감일 자동 검증 클래스",
      joinCode: "AUDIT1",
      battle: ClassBattleSummary.mocks[0],
      deadline: deadline,
      memberCount: 1,
      role: .owner,
      status: .open,
      allowsAnonymousOpinion: false,
      requiresComment: false
    )
    let repository = MockClassRepository(rooms: [room], availableRooms: [])
    self.room = room
    self.repository = repository
    var list = MyClassFeature.State()
    list.rooms = [room]
    list.viewState = .loaded
    var state = ClassCoordinator.State()
    state.routes.push(.myClasses(list))
    store = withDependencies {
      $0.date.now = now
      $0.uuid = .incrementing
    } operation: {
      Store(initialState: state) {
        ClassCoordinator()
          .dependency(\.classUseCase, repository)
          .dependency(\.classMockRepository, repository)
      }
    }
  }

  var body: some View {
    ZStack(alignment: .topLeading) {
      ClassCoordinatorView(store: store)
      diagnostics
    }
    .task {
      guard !hasOpened else { return }
      hasOpened = true
      store.send(.router(.routeAction(
        id: 1,
        action: .myClasses(.delegate(.openInformation(room)))
      )))
    }
    .task(id: store.deadlineEdit == nil) {
      guard hasOpened, store.deadlineEdit == nil else { return }
      do {
        persisted = try await repository.fetchMyClasses().first(where: { $0.id == room.id })?.deadline
        failed = persisted == nil
      } catch {
        failed = true
      }
    }
  }
}

private extension DeadlineAuditView {
  var diagnostics: some View {
    Text("Class UI audit")
      .pretendardFont(family: .Regular, size: 10)
      .accessibilityIdentifier("audit-state")
      .accessibilityValue(diagnosticValue)
      .allowsHitTesting(false)
  }

  var diagnosticValue: String {
    let listDeadline: Date? = store.routes.compactMap { route in
      guard case let .myClasses(list) = route.screen else { return nil }
      return list.rooms.first(where: { $0.id == room.id })?.deadline
    }.first
    let values = [
      "draft": canonical(store.deadlineEdit?.draftDeadline),
      "list": canonical(listDeadline),
      "persisted": canonical(persisted),
      "status": failed ? "error" : (persisted != nil && store.deadlineEdit == nil ? "saved" : "editing"),
    ]
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
