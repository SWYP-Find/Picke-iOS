import ClassDomainInterface
import ComposableArchitecture
import FeatureAssembly
import Foundation
@testable import Picke
import TCAFlow
import Testing

@MainActor
struct ProfileTicketCoordinatorTests {
  @Test
  func 마이페이지_이용권_메뉴는_선택_탭을_유지하고_등록_화면을_연다() async {
    let myPageTab = MainTabCoordinator.Tab.myPage.rawValue
    let store = TestStore(initialState: MainTabCoordinator.State(selectedTab: myPageTab)) {
      MainTabCoordinator()
    } withDependencies: {
      $0.uuid = .incrementing
    }
    store.exhaustivity = .off

    await store.send(.myPage(.router(.routeAction(
      id: 0,
      action: .profile(.delegate(.menuSelected(.ticketRegistration)))
    ))))

    #expect(store.state.selectedTab == myPageTab)
    #expect(store.state.myPageState.routes.count == 2)
    #expect(!store.state.shouldHideTabBar)
    guard case let .ticket(ticket)? = store.state.myPageState.routes.last?.screen else {
      Issue.record("이용권 등록 화면이 열리지 않았습니다")
      return
    }
    #expect(ticket.phase == .entry)
    await store.finish()
  }

  @Test
  func 등록_완료_후_개요를_열고_추가_등록_화면으로_이동한다() async {
    let start = Date(timeIntervalSince1970: 1_800_000_000)
    let end = Date(timeIntervalSince1970: 1_815_000_000)
    var registered = ClassTicketFeature.State()
    registered.phase = .registered
    registered.registrationStartDate = start
    registered.expirationDate = end
    var state = Picke.ProfileCoordinator.State()
    state.routes.push(.ticket(registered))
    let store = TestStore(initialState: state) { Picke.ProfileCoordinator() } withDependencies: {
      $0.uuid = .incrementing
    }
    store.exhaustivity = .off

    await store.send(.router(.routeAction(
      id: 1,
      action: .ticket(.delegate(.registrationConfirmed(startDate: start, endDate: end)))
    )))
    #expect(store.state.routes.count == 3)
    guard case let .ticket(overview)? = store.state.routes.last?.screen else {
      Issue.record("이용권 개요가 열리지 않았습니다")
      return
    }
    #expect(overview.phase == .overview)
    #expect(overview.registrationStartDate == start)

    await store.send(.router(.routeAction(
      id: 2,
      action: .ticket(.delegate(.addRegistrationRequested))
    )))
    guard case let .ticket(additional)? = store.state.routes.last?.screen else {
      Issue.record("추가 등록 화면이 열리지 않았습니다")
      return
    }
    #expect(additional.phase == .entry)
    #expect(!additional.shouldCheckExistingTicket)

    await store.finish()
  }

  @Test
  func 추가_등록_완료_후_기존_개요의_기간을_갱신한다() async {
    let start = Date(timeIntervalSince1970: 1_800_000_000)
    let end = Date(timeIntervalSince1970: 1_815_000_000)
    let laterEnd = end.addingTimeInterval(86400)
    var overview = ClassTicketFeature.State()
    overview.phase = .overview
    overview.registrationStartDate = start
    overview.expirationDate = end
    var completed = ClassTicketFeature.State()
    completed.phase = .registered
    completed.registrationStartDate = start
    completed.expirationDate = laterEnd
    var state = Picke.ProfileCoordinator.State()
    state.routes.push(.ticket(overview))
    state.routes.push(.ticket(completed))
    let store = TestStore(initialState: state) { Picke.ProfileCoordinator() }
    store.exhaustivity = .off

    await store.send(.router(.routeAction(
      id: 2,
      action: .ticket(.delegate(.registered(start, laterEnd)))
    )))
    guard case let .ticket(refreshed) = store.state.routes[1].screen else {
      Issue.record("기존 개요를 찾지 못했습니다")
      return
    }
    #expect(refreshed.expirationDate == laterEnd)

    await store.send(.router(.routeAction(
      id: 2,
      action: .ticket(.delegate(.registrationConfirmed(startDate: start, endDate: laterEnd)))
    )))
    #expect(store.state.routes.count == 2)
    guard case let .ticket(updated)? = store.state.routes.last?.screen else {
      Issue.record("추가 등록 후 개요가 유지되지 않았습니다")
      return
    }
    #expect(updated.expirationDate == laterEnd)
    await store.finish()
  }

  @Test
  func 개요_위에서_사용_중인_내_이용권을_다시_입력하면_기존_개요로_돌아간다() async {
    let ticket = profileActiveTicket()
    var overview = ClassTicketFeature.State(instanceID: UUID(10))
    overview.phase = .overview
    var registration = ClassTicketFeature.State(instanceID: UUID(11))
    registration.shouldCheckExistingTicket = false
    var state = Picke.ProfileCoordinator.State()
    state.routes.push(.ticket(overview))
    state.routes.push(.ticket(registration))
    let store = TestStore(initialState: state) { Picke.ProfileCoordinator() } withDependencies: {
      $0.uuid = .incrementing
    }
    store.exhaustivity = .off

    await store.send(.router(.routeAction(id: 2, action: .ticket(.delegate(.existingTicketFound(ticket))))))

    #expect(store.state.routes.count == 2)
    guard case let .ticket(current)? = store.state.routes.last?.screen else {
      Issue.record("기존 이용권 개요로 돌아가지 않았습니다")
      return
    }
    #expect(current.instanceID == UUID(10))
    #expect(current.phase == .overview)
    #expect(current.ticket == ticket)
  }

  @Test
  func 바로_연_등록_화면에서_사용_중인_내_이용권을_다시_입력하면_그_화면을_개요로_바꾼다() async {
    let ticket = profileActiveTicket()
    var registration = ClassTicketFeature.State(instanceID: UUID(12))
    registration.code = "PICKE30"
    var state = Picke.ProfileCoordinator.State()
    state.routes.push(.ticket(registration))
    let store = TestStore(initialState: state) { Picke.ProfileCoordinator() } withDependencies: {
      $0.uuid = .incrementing
    }
    store.exhaustivity = .off

    await store.send(.router(.routeAction(id: 1, action: .ticket(.delegate(.existingTicketFound(ticket))))))

    #expect(store.state.routes.count == 2)
    guard case let .ticket(current)? = store.state.routes.last?.screen else {
      Issue.record("이용권 화면이 사라졌습니다")
      return
    }
    #expect(current.instanceID == UUID(12))
    #expect(current.phase == .overview)
    #expect(current.ticket == ticket)
    #expect(current.preview == nil)
  }

  @Test
  func 이용권_화면을_닫으면_진입_조회도_취소한다() async {
    let ticketID = UUID(13)
    var state = Picke.ProfileCoordinator.State()
    state.routes.push(.ticket(ClassTicketFeature.State(instanceID: ticketID)))
    state.ticketInstanceIDs = [ticketID]
    let store = TestStore(initialState: state) { Picke.ProfileCoordinator() } withDependencies: {
      $0.uuid = .incrementing
      $0.classTicketUseCase = NeverEndingTicketUseCase()
    }
    store.exhaustivity = .off

    await store.send(.router(.routeAction(id: 1, action: .ticket(.view(.onAppear)))))
    await store.send(.router(.updateRoutes(Array(store.state.routes.dropLast()))))
    await store.finish(timeout: .seconds(1))

    #expect(store.state.routes.count == 1)
  }
}

private func profileActiveTicket() -> ClassTicket {
  ClassTicket(
    id: 7,
    capacity: 30,
    status: .active,
    activatedAt: Date(timeIntervalSince1970: 1_800_000_000),
    expiresAt: Date(timeIntervalSince1970: 1_815_000_000),
    remainingDays: 170,
    readGraceEndsAt: Date(timeIntervalSince1970: 1_817_592_000)
  )
}

/// 내 이용권 조회가 취소될 때까지 끝나지 않는 대역.
private struct NeverEndingTicketUseCase: ClassTicketInterface {
  func previewTicket(code _: String) async throws -> ClassTicketPreview {
    throw ClassTicketError.invalidCode
  }

  func registerTicket(code _: String) async throws -> ClassTicket {
    throw ClassTicketError.invalidCode
  }

  func fetchMyTicket() async throws -> ClassTicket {
    try await Task.sleep(for: .seconds(60))
    throw ClassTicketError.notFound
  }
}
