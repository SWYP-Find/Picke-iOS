//
//  ClassCreationDeadlineTests.swift
//  PickeTests
//
//  Created by Picke on 10/15/26.
//

import ComposableArchitecture
import DomainAssembly
import FeatureAssembly
import Foundation
@testable import Picke
import TCAFlow
import Testing

@MainActor
struct ClassCreationDeadlineTests {
  private let now = Date(timeIntervalSince1970: 1_800_000_000)

  @Test(arguments: [false, true])
  func 생성_마감일은_확정할_때만_원본에_반영한다(ai: Bool) async throws {
    let store = makeStore(ai: ai)
    let original = try setting(store).deadline
    await open(store)
    #expect(store.state.deadlineSelection != nil)
    let changed = now.addingTimeInterval(7200)
    await store.send(.deadlineSelection(.presented(.binding(.set(\.draftDeadline, changed)))))
    #expect(try setting(store).deadline == original)
    await store.send(.deadlineSelection(.presented(.view(.backTapped))))
    await store.receive(\.deadlineSelection.presented.delegate.dismiss)
    #expect(store.state.deadlineSelection == nil)
    #expect(try setting(store).deadline == original)
    await open(store)
    await store.send(.deadlineSelection(.presented(.binding(.set(\.draftDeadline, changed)))))
    await store.send(.deadlineSelection(.presented(.view(.confirmTapped))))
    await store.receive(\.deadlineSelection.presented.delegate.confirmed)
    #expect(store.state.deadlineSelection == nil)
    #expect(try setting(store).deadline == changed)
    #expect(store.state.routes.count == 2)
    await store.finish()
  }

  @Test(arguments: [false, true])
  func 추천에서_생성으로_push한_화면의_ID로_마감일을_연다(ai: Bool) async throws {
    var state = ClassCoordinator.State()
    state.routes.push(.recommend(.init(filter: .init())))
    let store = TestStore(initialState: state) { ClassCoordinator() } withDependencies: {
      $0.uuid = .incrementing
      $0.date.now = now
    }
    store.exhaustivity = .off
    if ai {
      await store.send(.router(.routeAction(id: 1, action: .recommend(.delegate(
        .selectAIQuestion(.examples[0], .init())
      )))))
    } else {
      await store.send(.router(.routeAction(id: 1, action: .recommend(.delegate(
        .select(ClassRoom.mockJoinable.battle)
      )))))
    }
    let origin = try setting(store)
    #expect(origin.instanceID == UUID(uuidString: "00000000-0000-0000-0000-000000000000"))
    #expect(store.state.routes.count == 3)
    await store.send(.router(.routeAction(id: 2, action: .setting(.view(.deadlineFieldTapped)))))
    await store.receive(\.router.routeAction)
    #expect(store.state.deadlineSelection?.settingInstanceID == origin.instanceID)
    await store.finish()
  }

  @Test
  func 확정_위임_직후_마감되면_즉시_오류를_표시한다() async throws {
    let clock = LockIsolated(now)
    let draft = now.addingTimeInterval(60)
    var state = ClassCoordinator.State()
    state.routes.push(.setting(.init(
      battle: ClassRoom.mockJoinable.battle,
      deadline: draft
    )))
    let store = TestStore(initialState: state) { ClassCoordinator() } withDependencies: {
      $0.date = .init { clock.value }
    }
    store.exhaustivity = .off
    await open(store)
    let origin = try setting(store)
    clock.withValue { $0 = draft.addingTimeInterval(1) }
    await store.send(.deadlineSelection(.presented(.delegate(.confirmed(
      draft,
      settingInstanceID: origin.instanceID
    )))))
    #expect(store.state.deadlineSelection?.canConfirm == false)
    #expect(store.state.deadlineSelection?.validationMessage != nil)
    #expect(try setting(store).deadline == origin.deadline)
    await store.finish()
  }

  @Test
  func 지난_마감일의_시트를_열면_다음_분부터_확정할_수_있다() async throws {
    let clock = LockIsolated(now)
    var state = ClassCoordinator.State()
    state.routes.push(.setting(.init(
      battle: ClassRoom.mockJoinable.battle,
      deadline: now.addingTimeInterval(-3600)
    )))
    let store = TestStore(initialState: state) { ClassCoordinator() } withDependencies: {
      $0.date = .init { clock.value }
    }
    store.exhaustivity = .off
    await open(store)
    let draft = try #require(store.state.deadlineSelection?.draftDeadline)
    #expect(draft == now.addingTimeInterval(60))
    clock.withValue { $0 = $0.addingTimeInterval(5) }
    await store.send(.deadlineSelection(.presented(.view(.confirmTapped))))
    await store.receive(\.deadlineSelection.presented.delegate.confirmed)
    #expect(try setting(store).deadline == draft)
    #expect(store.state.deadlineSelection == nil)
    await store.finish()
  }

  @Test
  func 뒤로가기는_시트만_닫고_루트이동은_둘다_닫는다() async {
    let store = makeStore()
    await open(store)
    await store.send(.view(.backAction))
    #expect(store.state.deadlineSelection == nil)
    #expect(store.state.routes.count == 2)
    await open(store)
    await store.send(.view(.backToRootAction))
    #expect(store.state.deadlineSelection == nil)
    #expect(store.state.routes.count == 1)
  }

  @Test
  func 같은_위치의_설정화면이_교체되면_이전_시트를_닫는다() async {
    let store = makeStore()
    await open(store)
    var routes = store.state.routes
    routes[screenAt: 1] = .setting(.init(battle: ClassRoom.mockJoinable.battle))
    await store.send(.router(.updateRoutes(routes)))
    #expect(store.state.deadlineSelection == nil)
  }

  @Test
  func 마감일을_끄면_시트를_닫고_다시_열지_않는다() async {
    let store = makeStore()
    await open(store)
    await store.send(.router(.routeAction(id: 1, action: .setting(.binding(.set(\.isDeadlineEnabled, false))))))
    #expect(store.state.deadlineSelection == nil)
    await store.send(.router(.routeAction(id: 1, action: .setting(.view(.deadlineFieldTapped)))))
    #expect(store.state.deadlineSelection == nil)
    await store.finish()
  }

  @Test
  func 지난_날짜는_확정하거나_클래스를_생성하지_않는다() async throws {
    let store = makeStore()
    await open(store)
    await store.send(.deadlineSelection(.presented(.binding(.set(\.draftDeadline, now.addingTimeInterval(-1))))))
    await store.send(.deadlineSelection(.presented(.view(.confirmTapped))))
    #expect(store.state.deadlineSelection?.validationMessage != nil)
    #expect(store.state.deadlineSelection?.canConfirm == false)
    #expect(store.state.deadlineSelection?.minimumSelectableDate == now.addingTimeInterval(-1))
    #expect(try setting(store).deadline > now)
    await store.send(.view(.backAction))

    var initial = try setting(store)
    initial.name = "마감된 클래스"
    initial.deadline = now.addingTimeInterval(-1)
    let creation = TestStore(initialState: initial) { ClassSettingFeature() } withDependencies: {
      $0.date.now = now
    }
    await creation.send(.view(.createTapped)) {
      $0.deadlineValidationMessage = "현재 이후 시간을 선택해 주세요."
    }
    await creation.finish()
    #expect(!creation.state.isLoading)
    await creation.send(.binding(.set(\.isDeadlineEnabled, false))) {
      $0.isDeadlineEnabled = false
      $0.deadlineValidationMessage = nil
    }
  }

  private func makeStore(ai: Bool = false) -> TestStoreOf<ClassCoordinator> {
    var state = ClassCoordinator.State()
    let deadline = now.addingTimeInterval(3600)
    let setting = ai
      ? ClassSettingFeature.State(aiQuestion: .examples[0], filter: .init(), deadline: deadline)
      : ClassSettingFeature.State(battle: ClassRoom.mockJoinable.battle, deadline: deadline)
    state.routes.push(.setting(setting))
    let store = TestStore(initialState: state) { ClassCoordinator() } withDependencies: {
      $0.date.now = now
    }
    store.exhaustivity = .off
    return store
  }

  private func open(_ store: TestStoreOf<ClassCoordinator>) async {
    await store.send(.router(.routeAction(id: 1, action: .setting(.view(.deadlineFieldTapped)))))
    await store.receive(\.router.routeAction)
  }

  private func setting(_ store: TestStoreOf<ClassCoordinator>) throws -> ClassSettingFeature.State {
    guard case let .setting(value)? = store.state.routes.last?.screen else {
      throw MissingSetting()
    }
    return value
  }

  private struct MissingSetting: Error {}
}
