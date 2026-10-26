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
}
