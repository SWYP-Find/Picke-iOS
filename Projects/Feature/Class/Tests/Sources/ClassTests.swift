//
//  ClassTests.swift
//  ClassTests
//
//  Created by Picke on 10/11/26.
//

@testable import Class
import ClassDomainInterface
import ComposableArchitecture
import Foundation
import Testing

@MainActor
struct ClassTests {
  @Test
  func 참여하기_탭하면_참가_경로_델리게이트를_보낸다() async {
    let store = TestStore(initialState: ClassIntroFeature.State()) {
      ClassIntroFeature()
    }

    await store.send(.view(.joinTapped))
    await store.receive(\.delegate.join)
  }

  @Test
  func 뒤로가면_홈_이동_델리게이트를_보낸다() async {
    let store = TestStore(initialState: ClassIntroFeature.State()) {
      ClassIntroFeature()
    }

    await store.send(.view(.backTapped))
    await store.receive(\.delegate.backToHome)
  }

  @Test
  func 내_클래스_탭하면_내_클래스_델리게이트를_보낸다() async {
    let store = TestStore(initialState: ClassIntroFeature.State()) {
      ClassIntroFeature()
    }

    await store.send(.view(.myClassesTapped))
    await store.receive(\.delegate.myClasses)
  }

  @Test
  func 새_클래스_만들기는_사용_중인_이용권이면_생성_델리게이트를_보낸다() async {
    let store = TestStore(initialState: ClassIntroFeature.State()) {
      ClassIntroFeature()
    } withDependencies: {
      $0.classTicketUseCase = TicketStub(myTicket: .success(introTicket(.active)))
    }

    await store.send(.view(.createTapped)) { $0.isCheckingTicket = true }
    await store.receive(\.inner.ticketResponse) { $0.isCheckingTicket = false }
    await store.receive(\.delegate.create)
  }

  @Test
  func 새_클래스_만들기는_이용권이_만료되면_등록_안내를_띄우고_등록하기로_이동한다() async {
    let store = TestStore(initialState: ClassIntroFeature.State()) {
      ClassIntroFeature()
    } withDependencies: {
      $0.classTicketUseCase = TicketStub(myTicket: .success(introTicket(.expired)))
    }

    await store.send(.view(.createTapped)) { $0.isCheckingTicket = true }
    await store.receive(\.inner.ticketResponse) {
      $0.isCheckingTicket = false
      $0.ticketNotice = .expired
      $0.customAlert = .classTicketExpired()
    }
    await store.send(.customAlert(.presented(.confirmTapped))) {
      $0.ticketNotice = nil
      $0.customAlert = nil
    }
    await store.receive(\.delegate.registerTicket)
  }

  @Test
  func 새_클래스_만들기는_만료_안내에서_뒤로가기를_누르면_머문다() async {
    let store = TestStore(initialState: ClassIntroFeature.State()) {
      ClassIntroFeature()
    } withDependencies: {
      $0.classTicketUseCase = TicketStub(myTicket: .success(introTicket(.expired)))
    }

    await store.send(.view(.createTapped)) { $0.isCheckingTicket = true }
    await store.receive(\.inner.ticketResponse) {
      $0.isCheckingTicket = false
      $0.ticketNotice = .expired
      $0.customAlert = .classTicketExpired()
    }
    await store.send(.customAlert(.presented(.cancelTapped))) {
      $0.ticketNotice = nil
      $0.customAlert = nil
    }
  }

  @Test
  func 새_클래스_만들기는_이용권이_없으면_안내만_띄운다() async {
    let store = TestStore(initialState: ClassIntroFeature.State()) {
      ClassIntroFeature()
    } withDependencies: {
      $0.classTicketUseCase = TicketStub(myTicket: .failure(.notFound))
    }

    await store.send(.view(.createTapped)) { $0.isCheckingTicket = true }
    await store.receive(\.inner.ticketResponse) {
      $0.isCheckingTicket = false
      $0.ticketNotice = .required
      $0.customAlert = .classTicketRequired()
    }
    await store.send(.customAlert(.presented(.confirmTapped))) {
      $0.ticketNotice = nil
      $0.customAlert = nil
    }
  }

  @Test
  func 새_클래스_만들기에서_이용권_조회가_실패하면_토스트를_띄운다() async {
    let store = TestStore(initialState: ClassIntroFeature.State()) {
      ClassIntroFeature()
    } withDependencies: {
      $0.classTicketUseCase = TicketStub(myTicket: .failure(.network("연결 실패")))
    }

    await store.send(.view(.createTapped)) { $0.isCheckingTicket = true }
    await store.receive(\.inner.ticketResponse) {
      $0.isCheckingTicket = false
      $0.toastMessage = "정보를 불러오지 못했어요"
    }
    await store.send(.view(.toastShown)) { $0.toastMessage = nil }
  }

  @Test
  func 이용권_확인_중_다시_누르면_무시하고_뒤로_가면_확인을_취소한다() async {
    let store = TestStore(initialState: ClassIntroFeature.State()) {
      ClassIntroFeature()
    } withDependencies: {
      $0.classTicketUseCase = TicketStub(myTicketFetch: {
        try await Task.sleep(for: .seconds(60))
        throw ClassTicketError.notFound
      })
    }

    await store.send(.view(.createTapped)) { $0.isCheckingTicket = true }
    await store.send(.view(.createTapped))
    await store.send(.view(.backTapped)) { $0.isCheckingTicket = false }
    await store.receive(\.delegate.backToHome)
    await store.finish(timeout: .seconds(1))
  }

  @Test
  func 이용권_탭하면_등록_화면으로_이동한다() async {
    let store = TestStore(initialState: ClassIntroFeature.State()) {
      ClassIntroFeature()
    }

    await store.send(.view(.ticketTapped))
    await store.receive(\.delegate.ticket)
  }

  @Test
  func 같은_카테고리를_다시_누르면_선택이_해제된다() async {
    let store = TestStore(initialState: ClassTopicFeature.State()) {
      ClassTopicFeature()
    }

    await store.send(.view(.categoryTapped(.philosophy))) {
      $0.categories = [.philosophy]
    }
    await store.send(.view(.categoryTapped(.philosophy))) {
      $0.categories = []
    }
  }

  @Test
  func 카테고리는_최대_세_개까지_선택하고_해제하면_다시_추가할_수_있다() async {
    let store = TestStore(initialState: ClassTopicFeature.State()) {
      ClassTopicFeature()
    }

    await store.send(.view(.categoryTapped(.philosophy))) {
      $0.categories = [.philosophy]
    }
    await store.send(.view(.categoryTapped(.society))) {
      $0.categories = [.philosophy, .society]
    }
    await store.send(.view(.categoryTapped(.literature))) {
      $0.categories = [.philosophy, .society, .literature]
    }
    await store.send(.view(.categoryTapped(.science)))
    await store.send(.view(.categoryTapped(.society))) {
      $0.categories = [.philosophy, .literature]
    }
    await store.send(.view(.categoryTapped(.science))) {
      $0.categories = [.philosophy, .literature, .science]
    }
  }

  @Test
  func 콘텐츠_보기_탭하면_선택한_조건으로_검색_델리게이트를_보낸다() async {
    var state = ClassTopicFeature.State()
    state.keyword = "  촉법소년 "
    state.level = .high
    state.categories = [.society, .philosophy]
    let store = TestStore(initialState: state) {
      ClassTopicFeature()
    }

    await store.send(.view(.searchTapped))
    await store.receive(\.delegate.search, ClassTopicFilter(
      keyword: "촉법소년",
      level: .high,
      categories: [.society, .philosophy]
    ))
  }
}

private func introTicket(_ status: ClassTicket.Status) -> ClassTicket {
  ClassTicket(
    id: 3,
    capacity: 15,
    status: status,
    activatedAt: Date(timeIntervalSince1970: 1_780_000_000),
    expiresAt: Date(timeIntervalSince1970: 1_795_000_000),
    remainingDays: 0,
    readGraceEndsAt: Date(timeIntervalSince1970: 1_797_592_000)
  )
}
