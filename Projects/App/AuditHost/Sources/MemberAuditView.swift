//
//  MemberAuditView.swift
//  PickeClassAuditHost
//
//  Created by Picke on 10/16/26.
//

import ComposableArchitecture
import DomainAssembly
import FeatureAssembly
import Foundation
import PickeDesignKit
import SwiftUI
import TCAFlow
import UIKit

/// Isolated fixture for tapping the production class list and member screens.
struct MemberAuditView: View {
  static let targetTitle = "회원 검증 대상 클래스"
  static let survivorTitle = "회원 검증 유지 클래스"

  @Bindable private var store: StoreOf<ClassCoordinator>
  private let repository: MockClassRepository
  private let scenario: String
  @State private var persistedRoomIDs: [Int] = []
  @State private var persistedMemberIDs: [Int] = []
  @State private var persistedCount: Int?
  @State private var currentMemberID: Int?
  @State private var snapshotKey = ""
  @State private var snapshotError = ""
  @State private var nativeNameObserved = false
  @State private var nativeNameFocused = false
  @State private var nativeNameBeginCount = 0
  @State private var nativeNameEndCount = 0
  @State private var nativeNameChangeCount = 0
  @State private var nativeNameValue = ""

  init(scenario: String) {
    self.scenario = scenario
    let owner = scenario == "owner-remove"
    let deadline = Date(timeIntervalSince1970: 1_893_456_000)
    let source = ClassRoom.mocks[0]
    let target = ClassRoom(
      id: 1,
      name: Self.targetTitle,
      joinCode: "AUDIT1",
      battle: source.battle,
      deadline: deadline,
      memberCount: MockClassRepository.figmaOwnerMembers.count,
      role: owner ? .owner : .member,
      status: .open,
      allowsAnonymousOpinion: source.allowsAnonymousOpinion,
      requiresComment: source.requiresComment,
      memberCapacity: source.memberCapacity
    )
    let survivor = ClassRoom(
      id: 2,
      name: Self.survivorTitle,
      joinCode: "AUDIT2",
      battle: source.battle,
      deadline: deadline,
      memberCount: MockClassRepository.figmaOwnerMembers.count,
      role: .member,
      status: .open,
      allowsAnonymousOpinion: source.allowsAnonymousOpinion,
      requiresComment: source.requiresComment,
      memberCapacity: source.memberCapacity
    )
    let rooms = owner ? [target] : [target, survivor]
    let repository = MockClassRepository(
      rooms: rooms,
      availableRooms: [],
      members: Dictionary(uniqueKeysWithValues: rooms.map { room in
        (
          room.id,
          room.role == .owner
            ? MockClassRepository.figmaOwnerMembers
            : MockClassRepository.figmaParticipantMembers
        )
      })
    )
    self.repository = repository
    var list = MyClassFeature.State()
    list.rooms = rooms
    list.viewState = .loaded
    var state = ClassCoordinator.State()
    state.routes.push(.myClasses(list))
    store = withDependencies {
      $0.date.now = Date(timeIntervalSince1970: 1_893_000_000)
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
    ZStack(alignment: .bottomTrailing) {
      ClassCoordinatorView(store: store)
      diagnostics
        .padding(4)
    }
    .task(id: routeSnapshotKey) {
      await refreshSnapshot(for: routeSnapshotKey)
    }
    .onReceive(NotificationCenter.default.publisher(for: UITextField.textDidBeginEditingNotification)) {
      recordNameFieldEvent($0, kind: .begin)
    }
    .onReceive(NotificationCenter.default.publisher(for: UITextField.textDidEndEditingNotification)) {
      recordNameFieldEvent($0, kind: .end)
    }
    .onReceive(NotificationCenter.default.publisher(for: UITextField.textDidChangeNotification)) {
      recordNameFieldEvent($0, kind: .change)
    }
  }
}

private extension MemberAuditView {
  enum NameFieldEvent {
    case begin
    case end
    case change
  }

  func recordNameFieldEvent(
    _ notification: Notification,
    kind: NameFieldEvent
  ) {
    guard let field = notification.object as? UITextField,
          field.placeholder == "이름을 입력해주세요" else { return }
    nativeNameObserved = true
    // Focus sampled at the last native field event, not a continuously observed value.
    nativeNameFocused = field.isFirstResponder
    nativeNameValue = field.text ?? ""
    switch kind {
    case .begin: nativeNameBeginCount += 1
    case .end: nativeNameEndCount += 1
    case .change: nativeNameChangeCount += 1
    }
  }

  var diagnostics: some View {
    Text("Member UI audit")
      .pretendardFont(family: .Regular, size: 10)
      .accessibilityIdentifier("audit-member-state")
      .accessibilityValue(diagnosticValue)
      .allowsHitTesting(false)
  }

  var routeKind: String {
    guard let screen = store.routes.last?.screen else { return "none" }
    switch screen {
    case .myClasses: return "list"
    case .detail: return "detail"
    case .members: return "members"
    default: return "other"
    }
  }

  var listRooms: [ClassRoom] {
    store.routes.compactMap { route in
      guard case let .myClasses(list) = route.screen else { return nil }
      return list.rooms
    }.first ?? []
  }

  var visibleMemberIDs: [Int] {
    guard case let .members(member)? = store.routes.last?.screen else { return [] }
    return member.members.map(\.id).sorted()
  }

  var routeSnapshotKey: String {
    let rooms = listRooms.map { "\($0.id):\($0.memberCount)" }.joined(separator: ",")
    return "\(routeKind)|\(rooms)|\(visibleMemberIDs)"
  }

  var diagnosticValue: String {
    let values: [String: Any] = [
      "scenario": scenario,
      "route": routeKind,
      "listRoomIDs": listRooms.map(\.id).sorted(),
      "listTargetCount": listRooms.first(where: { $0.id == 1 })?.memberCount ?? -1,
      "visibleMemberIDs": visibleMemberIDs,
      "persistedRoomIDs": persistedRoomIDs,
      "persistedMemberIDs": persistedMemberIDs,
      "persistedTargetCount": persistedCount ?? -1,
      "currentMemberID": currentMemberID ?? -1,
      "snapshotKey": snapshotKey,
      "routeSnapshotKey": routeSnapshotKey,
      "status": snapshotError.isEmpty && snapshotKey == routeSnapshotKey ? "ready" : "pending",
      "error": snapshotError,
      "nativeNameObserved": nativeNameObserved,
      "nativeNameFocused": nativeNameFocused,
      "nativeNameBeginCount": nativeNameBeginCount,
      "nativeNameEndCount": nativeNameEndCount,
      "nativeNameChangeCount": nativeNameChangeCount,
      "nativeNameValue": nativeNameValue,
    ]
    guard let data = try? JSONSerialization.data(withJSONObject: values, options: [.sortedKeys]),
          let json = String(data: data, encoding: .utf8) else { return "{}" }
    return json
  }

  func refreshSnapshot(for key: String) async {
    do {
      let rooms = try await repository.fetchMyClasses()
      let members = try await repository.fetchMembers(roomID: 1)
      let currentID = try? await repository.currentMemberID(roomID: 1)
      let survivorMembers = scenario == "member-leave" ? try await repository.fetchMembers(roomID: 2) : []
      let survivorCurrentID = scenario == "member-leave" ? try await repository.currentMemberID(roomID: 2) : 1
      let roomIDs = rooms.map(\.id).sorted()
      let memberIDs = members.map(\.id).sorted()
      let expectedInitialRooms = scenario == "owner-remove" ? [1] : [1, 2]
      guard Set(roomIDs).count == roomIDs.count,
            Set(memberIDs).count == memberIDs.count,
            memberIDs.contains(1),
            !snapshotKey.isEmpty || (roomIDs == expectedInitialRooms && memberIDs.contains(2)),
            !snapshotKey.isEmpty || currentID == (scenario == "owner-remove" ? 1 : 2),
            scenario == "owner-remove" || (survivorCurrentID == 2 && survivorMembers.contains(where: { $0.id == 2 }))
      else {
        snapshotError = "invalid fixture IDs or current member"
        return
      }
      persistedRoomIDs = roomIDs
      persistedMemberIDs = memberIDs
      persistedCount = rooms.first(where: { $0.id == 1 })?.memberCount
      currentMemberID = currentID
      snapshotError = ""
      snapshotKey = key
    } catch {
      snapshotError = error.localizedDescription
    }
  }
}
