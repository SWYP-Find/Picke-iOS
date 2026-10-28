@testable import Class
import ClassDomainInterface
import ComposableArchitecture
import Foundation
import PickeCoreUtility
import Testing

@MainActor
struct ClassTicketTests {
  @Test
  func 진입_시_내_이용권이_있으면_개요를_표시한다() async {
    let start = Date(timeIntervalSince1970: 1_780_000_000)
    let end = Date(timeIntervalSince1970: 1_795_000_000)
    let ticket = ClassTicket(
      id: 3,
      capacity: 30,
      status: .active,
      activatedAt: start,
      expiresAt: end,
      remainingDays: 162,
      readGraceEndsAt: Date(timeIntervalSince1970: 1_797_592_000)
    )
    let store = TestStore(initialState: ClassTicketFeature.State()) { ClassTicketFeature() } withDependencies: {
      $0.classTicketUseCase = TicketStub(myTicket: .success(ticket))
    }

    await store.send(.view(.onAppear)) {
      $0.shouldCheckExistingTicket = false
      $0.isLoadingExistingTicket = true
    }
    await store.receive(\.myTicketResponse) {
      $0.isLoadingExistingTicket = false
      $0.ticket = ticket
      $0.registrationStartDate = start
      $0.expirationDate = end
      $0.phase = .overview
    }
    await store.send(.view(.onAppear))
  }

  @Test
  func 최초_이용권_조회_중_코드를_입력해도_기존_이용권으로_이동한다() async {
    let ticket = ClassTicket(
      id: 4,
      capacity: 15,
      status: .active,
      activatedAt: Date(timeIntervalSince1970: 1_780_000_000),
      expiresAt: Date(timeIntervalSince1970: 1_795_000_000),
      remainingDays: 162,
      readGraceEndsAt: Date(timeIntervalSince1970: 1_797_592_000)
    )
    let gate = TicketLookupGate()
    let store = TestStore(initialState: ClassTicketFeature.State()) { ClassTicketFeature() } withDependencies: {
      $0.classTicketUseCase = TicketStub(myTicketFetch: { try await gate.wait() })
    }

    await store.send(.view(.onAppear)) {
      $0.shouldCheckExistingTicket = false
      $0.isLoadingExistingTicket = true
    }
    await store.send(.binding(.set(\.code, "PICKE-AB12-CD34"))) {
      $0.code = "PICKE-AB12-CD34"
    }
    #expect(!store.state.canCheckCode)
    await gate.complete(ticket)
    await store.receive(\.myTicketResponse) {
      $0.isLoadingExistingTicket = false
      $0.ticket = ticket
      $0.registrationStartDate = ticket.activatedAt
      $0.expirationDate = ticket.expiresAt
      $0.phase = .overview
    }
  }

  @Test
  func 등록된_이용권이_없으면_코드_입력_화면에_남는다() async {
    let store = TestStore(initialState: ClassTicketFeature.State()) { ClassTicketFeature() } withDependencies: {
      $0.classTicketUseCase = TicketStub(myTicket: .failure(.notFound))
    }

    await store.send(.view(.onAppear)) {
      $0.shouldCheckExistingTicket = false
      $0.isLoadingExistingTicket = true
    }
    await store.receive(\.myTicketResponse) { $0.isLoadingExistingTicket = false }
    #expect(store.state.phase == .entry)
    #expect(store.state.errorMessage == nil)
    await store.send(.view(.onAppear))
  }

  @Test
  func 만료된_이용권은_사용_중으로_표시하지_않는다() async {
    let ticket = ClassTicket(
      id: 3,
      capacity: 15,
      status: .expired,
      activatedAt: Date(timeIntervalSince1970: 1_780_000_000),
      expiresAt: Date(timeIntervalSince1970: 1_795_000_000),
      remainingDays: 0,
      readGraceEndsAt: Date(timeIntervalSince1970: 1_797_592_000)
    )
    let store = TestStore(initialState: ClassTicketFeature.State()) { ClassTicketFeature() } withDependencies: {
      $0.classTicketUseCase = TicketStub(myTicket: .success(ticket))
    }

    await store.send(.view(.onAppear)) {
      $0.shouldCheckExistingTicket = false
      $0.isLoadingExistingTicket = true
    }
    await store.receive(\.myTicketResponse) {
      $0.isLoadingExistingTicket = false
      $0.ticket = ticket
      $0.registrationStartDate = ticket.activatedAt
      $0.expirationDate = ticket.expiresAt
      $0.phase = .overview
    }
    #expect(store.state.overviewTitle == "만료된 이용권")
  }

  @Test
  func 추가_등록_화면은_기존_이용권을_다시_조회하지_않는다() async {
    var state = ClassTicketFeature.State()
    state.shouldCheckExistingTicket = false
    let store = TestStore(initialState: state) { ClassTicketFeature() } withDependencies: {
      $0.classTicketUseCase = TicketStub(myTicket: .failure(.network("호출되면 안 됨")))
    }

    await store.send(.view(.onAppear))
    #expect(store.state.phase == .entry)
  }

  @Test
  func 확인은_미리보기만_표시하고_등록은_서버_기간을_그대로_사용한다() async {
    let start = Date(timeIntervalSince1970: 1_780_000_000)
    let end = Date(timeIntervalSince1970: 1_795_000_000)
    let preview = ClassTicketPreview(
      capacity: 15,
      registerBy: Date(timeIntervalSince1970: 1_800_000_000),
      usageMonths: 6,
      registeredByMe: false
    )
    let ticket = ClassTicket(
      id: 3,
      capacity: 15,
      status: .active,
      activatedAt: start,
      expiresAt: end,
      remainingDays: 162,
      readGraceEndsAt: Date(timeIntervalSince1970: 1_797_592_000)
    )
    var state = ClassTicketFeature.State()
    state.code = "PICKE-AB12-CD34"
    let store = TestStore(initialState: state) { ClassTicketFeature() } withDependencies: {
      $0.classTicketUseCase = TicketStub(preview: .success(preview), register: .success(ticket))
    }

    await store.send(.view(.checkTapped)) { $0.isChecking = true }
    await store.receive(\.checkResponse) {
      $0.isChecking = false
      $0.preview = preview
      $0.phase = .preview
    }
    #expect(store.state.ticket == nil)
    #expect(store.state.capacity == 15)
    await store.send(.view(.confirmTapped)) { $0.isChecking = true }
    await store.receive(\.registrationResponse) {
      $0.isChecking = false
      $0.ticket = ticket
      $0.phase = .registered
      $0.registrationStartDate = start
      $0.expirationDate = end
    }
    await store.receive(\.delegate, .registered(start, end))
    #expect(store.state.periodText == "\(start.formatted(.yearMonthDayDotted)) – \(end.formatted(.yearMonthDayDotted))")
    await store.send(.view(.confirmTapped))
    await store.receive(\.delegate, .registrationConfirmed(startDate: start, endDate: end))
  }

  @Test
  func 이미_등록한_코드는_내_이용권_조회로_이동한다() async {
    let start = Date(timeIntervalSince1970: 1_780_000_000)
    let end = Date(timeIntervalSince1970: 1_795_000_000)
    let preview = ClassTicketPreview(
      capacity: 30,
      registerBy: Date(timeIntervalSince1970: 1_800_000_000),
      usageMonths: 6,
      registeredByMe: true
    )
    let ticket = ClassTicket(
      id: 3,
      capacity: 30,
      status: .active,
      activatedAt: start,
      expiresAt: end,
      remainingDays: 162,
      readGraceEndsAt: Date(timeIntervalSince1970: 1_797_592_000)
    )
    var state = ClassTicketFeature.State()
    state.code = "PICKE-AB12-CD34"
    let store = TestStore(initialState: state) { ClassTicketFeature() } withDependencies: {
      $0.classTicketUseCase = TicketStub(preview: .success(preview), myTicket: .success(ticket))
    }

    await store.send(.view(.checkTapped)) { $0.isChecking = true }
    await store.receive(\.checkResponse) {
      $0.isChecking = false
      $0.isLoadingExistingTicket = true
      $0.preview = preview
    }
    await store.receive(\.myTicketResponse) {
      $0.isLoadingExistingTicket = false
      $0.ticket = ticket
      $0.phase = .overview
      $0.registrationStartDate = start
      $0.expirationDate = end
    }
  }

  @Test
  func 서버_거절_사유를_보여주고_등록을_막는다() async {
    var state = ClassTicketFeature.State()
    state.code = "EXPIRED"
    let store = TestStore(initialState: state) { ClassTicketFeature() } withDependencies: {
      $0.classTicketUseCase = TicketStub(preview: .failure(.registrationExpired))
    }

    await store.send(.view(.checkTapped)) { $0.isChecking = true }
    await store.receive(\.checkResponse) {
      $0.isChecking = false
      $0.errorMessage = ClassTicketError.registrationExpired.message
    }
    #expect(store.state.phase == .entry)
  }
}

private struct TicketStub: ClassTicketInterface {
  var preview: Result<ClassTicketPreview, ClassTicketError> = .failure(.invalidCode)
  var register: Result<ClassTicket, ClassTicketError> = .failure(.invalidCode)
  var myTicket: Result<ClassTicket, ClassTicketError> = .failure(.notFound)
  var myTicketFetch: (@Sendable () async throws -> ClassTicket)?

  func previewTicket(code _: String) async throws -> ClassTicketPreview {
    try preview.get()
  }

  func registerTicket(code _: String) async throws -> ClassTicket {
    try register.get()
  }

  func fetchMyTicket() async throws -> ClassTicket {
    if let myTicketFetch { return try await myTicketFetch() }
    return try myTicket.get()
  }
}

private actor TicketLookupGate {
  private var continuation: CheckedContinuation<ClassTicket, Error>?
  private var bufferedTicket: ClassTicket?

  func wait() async throws -> ClassTicket {
    if let bufferedTicket { return bufferedTicket }
    return try await withCheckedThrowingContinuation { continuation = $0 }
  }

  func complete(_ ticket: ClassTicket) {
    if let continuation {
      continuation.resume(returning: ticket)
      self.continuation = nil
    } else {
      bufferedTicket = ticket
    }
  }
}
