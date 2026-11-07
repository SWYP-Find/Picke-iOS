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
    await store.receive(\.existingTicketResponse) {
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
    await store.receive(\.existingTicketResponse) {
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
    await store.receive(\.existingTicketResponse) { $0.isLoadingExistingTicket = false }
    #expect(store.state.phase == .entry)
    #expect(store.state.customAlert == nil)
    await store.send(.view(.onAppear))
  }

  @Test
  func 만료된_이용권은_개요_대신_코드_입력부터_시작한다() async {
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
    await store.receive(\.existingTicketResponse) { $0.isLoadingExistingTicket = false }
    #expect(store.state.phase == .entry)
    #expect(store.state.ticket == nil)
  }

  @Test
  func 진입_조회가_실패하면_토스트를_띄운_뒤_화면을_닫는다() async {
    let store = TestStore(initialState: ClassTicketFeature.State()) { ClassTicketFeature() } withDependencies: {
      $0.classTicketUseCase = TicketStub(myTicket: .failure(.network("연결 실패")))
    }

    await store.send(.view(.onAppear)) {
      $0.shouldCheckExistingTicket = false
      $0.isLoadingExistingTicket = true
    }
    await store.receive(\.existingTicketResponse) {
      $0.isLoadingExistingTicket = false
      $0.toastMessage = "정보를 불러오지 못했어요"
      $0.closesAfterToast = true
    }
    await store.send(.view(.toastShown)) {
      $0.toastMessage = nil
      $0.closesAfterToast = false
    }
    await store.receive(\.delegate.dismiss)
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
    await store.receive(\.registeredTicketResponse) { $0.isLoadingExistingTicket = false }
    await store.receive(\.delegate, .existingTicketFound(ticket))
  }

  @Test
  func 내가_등록한_만료_이용권_코드는_만료_안내를_띄운다() async {
    let preview = ClassTicketPreview(
      capacity: 30,
      registerBy: Date(timeIntervalSince1970: 1_800_000_000),
      usageMonths: 6,
      registeredByMe: true
    )
    let ticket = ClassTicket(
      id: 3,
      capacity: 30,
      status: .expired,
      activatedAt: Date(timeIntervalSince1970: 1_780_000_000),
      expiresAt: Date(timeIntervalSince1970: 1_795_000_000),
      remainingDays: 0,
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
    await store.receive(\.registeredTicketResponse) {
      $0.isLoadingExistingTicket = false
      $0.registerNotice = .registrationExpired
      $0.customAlert = .ticketRegistrationExpired()
    }
  }

  @Test
  func 내_코드_재확인_중_코드를_고치면_조회를_취소한다() async {
    let preview = ClassTicketPreview(
      capacity: 30,
      registerBy: Date(timeIntervalSince1970: 1_800_000_000),
      usageMonths: 6,
      registeredByMe: true
    )
    var state = ClassTicketFeature.State()
    state.code = "PICKE-AB12-CD34"
    let store = TestStore(initialState: state) { ClassTicketFeature() } withDependencies: {
      $0.classTicketUseCase = TicketStub(preview: .success(preview), myTicketFetch: {
        try await Task.sleep(for: .seconds(60))
        throw ClassTicketError.notFound
      })
    }

    await store.send(.view(.checkTapped)) { $0.isChecking = true }
    await store.receive(\.checkResponse) {
      $0.isChecking = false
      $0.isLoadingExistingTicket = true
      $0.preview = preview
    }
    await store.send(.binding(.set(\.code, "PICKE-ZZ99"))) {
      $0.code = "PICKE-ZZ99"
      $0.preview = nil
      $0.isLoadingExistingTicket = false
    }
    await store.finish(timeout: .seconds(1))
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
      $0.registerNotice = .registrationExpired
      $0.customAlert = .ticketRegistrationExpired()
    }
    #expect(store.state.phase == .entry)
  }

  @Test
  func 다른_계정에_등록된_코드_안내는_배경_탭이면_머물고_뒤로가기면_닫는다() async {
    var state = ClassTicketFeature.State()
    state.code = "CLAIMED"
    let store = TestStore(initialState: state) { ClassTicketFeature() } withDependencies: {
      $0.classTicketUseCase = TicketStub(preview: .failure(.claimed))
    }

    await store.send(.view(.checkTapped)) { $0.isChecking = true }
    await store.receive(\.checkResponse) {
      $0.isChecking = false
      $0.registerNotice = .alreadyRegistered
      $0.customAlert = .ticketAlreadyRegistered()
    }
    await store.send(.customAlert(.presented(.cancelTapped))) {
      $0.registerNotice = nil
      $0.customAlert = nil
    }

    await store.send(.view(.checkTapped)) { $0.isChecking = true }
    await store.receive(\.checkResponse) {
      $0.isChecking = false
      $0.registerNotice = .alreadyRegistered
      $0.customAlert = .ticketAlreadyRegistered()
    }
    await store.send(.customAlert(.presented(.confirmTapped))) {
      $0.registerNotice = nil
      $0.customAlert = nil
    }
    await store.receive(\.delegate.dismiss)
  }

  @Test
  func 등록_오류는_Android와_같은_안내로_바꾸고_사용_중_이용권만_따로_안내한다() {
    #expect(ClassTicketRegisterNotice(error: .claimed) == .alreadyRegistered)
    #expect(ClassTicketRegisterNotice(error: .invalidCode) == .invalidCode)
    #expect(ClassTicketRegisterNotice(error: .revoked) == .invalidCode)
    #expect(ClassTicketRegisterNotice(error: .registrationExpired) == .registrationExpired)
    #expect(ClassTicketRegisterNotice(error: .activeTicket) == .alreadyActive)
    #expect(ClassTicketRegisterNotice(error: .notFound) == .registerFailed)
    #expect(ClassTicketRegisterNotice(error: .invalidResponse) == .registerFailed)
    #expect(ClassTicketRegisterNotice(error: .network("x")) == .registerFailed)
  }

  @Test
  func 확인_단계에서_뒤로가면_코드_입력으로_돌아가고_등록_중에는_무시한다() async {
    var state = ClassTicketFeature.State()
    state.code = "PICKE-AB12-CD34"
    state.phase = .preview
    state.preview = ClassTicketPreview(
      capacity: 15,
      registerBy: Date(timeIntervalSince1970: 1_800_000_000),
      usageMonths: 6,
      registeredByMe: false
    )
    state.isChecking = true
    let store = TestStore(initialState: state) { ClassTicketFeature() }

    await store.send(.view(.backTapped))
    await store.send(.binding(.set(\.isChecking, false))) { $0.isChecking = false }
    await store.send(.view(.backTapped)) {
      $0.phase = .entry
      $0.preview = nil
    }
  }

  @Test
  func 코드는_영문_숫자_하이픈만_대문자로_남긴다() {
    var state = ClassTicketFeature.State()
    state.code = " picke-ab12 cd34!한"
    #expect(state.normalizedCode == "PICKE-AB12CD34")
    #expect(state.canCheckCode)
    state.code = " !한 "
    #expect(!state.canCheckCode)
    #expect(state.ticketPeriodText == "")
    state.code = "1\u{FE0F}\u{20E3}A\u{0332}"
    #expect(state.normalizedCode == "1A")
  }

  @Test
  func 코드_확인과_등록은_정규화한_코드를_보낸다() async {
    let codes = LockIsolated<[String]>([])
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
      activatedAt: Date(timeIntervalSince1970: 1_780_000_000),
      expiresAt: Date(timeIntervalSince1970: 1_795_000_000),
      remainingDays: 162,
      readGraceEndsAt: Date(timeIntervalSince1970: 1_797_592_000)
    )
    var state = ClassTicketFeature.State()
    state.code = " picke-ab12 cd34"
    let store = TestStore(initialState: state) { ClassTicketFeature() } withDependencies: {
      $0.classTicketUseCase = TicketStub(
        preview: .success(preview),
        register: .success(ticket),
        submittedCodes: codes
      )
    }
    store.exhaustivity = .off

    await store.send(.view(.checkTapped))
    await store.receive(\.checkResponse)
    await store.send(.view(.confirmTapped))
    await store.receive(\.registrationResponse)

    #expect(codes.value == ["PICKE-AB12CD34", "PICKE-AB12CD34"])
  }

  @Test
  func 내_코드_재확인_조회가_실패하면_등록_실패_안내를_띄운다() async {
    let preview = ClassTicketPreview(
      capacity: 30,
      registerBy: Date(timeIntervalSince1970: 1_800_000_000),
      usageMonths: 6,
      registeredByMe: true
    )
    var state = ClassTicketFeature.State()
    state.code = "PICKE-AB12-CD34"
    let store = TestStore(initialState: state) { ClassTicketFeature() } withDependencies: {
      $0.classTicketUseCase = TicketStub(
        preview: .success(preview),
        myTicket: .failure(.network("연결 실패"))
      )
    }

    await store.send(.view(.checkTapped)) { $0.isChecking = true }
    await store.receive(\.checkResponse) {
      $0.isChecking = false
      $0.isLoadingExistingTicket = true
      $0.preview = preview
    }
    await store.receive(\.registeredTicketResponse) {
      $0.isLoadingExistingTicket = false
      $0.registerNotice = .registerFailed
      $0.customAlert = .ticketRegisterFailed()
    }
  }

  @Test
  func 등록이_사용_중_이용권으로_거절되면_사용_중_안내를_띄운다() async {
    let preview = ClassTicketPreview(
      capacity: 15,
      registerBy: Date(timeIntervalSince1970: 1_800_000_000),
      usageMonths: 6,
      registeredByMe: false
    )
    var state = ClassTicketFeature.State()
    state.code = "PICKE-AB12-CD34"
    let store = TestStore(initialState: state) { ClassTicketFeature() } withDependencies: {
      $0.classTicketUseCase = TicketStub(
        preview: .success(preview),
        register: .failure(.activeTicket)
      )
    }

    await store.send(.view(.checkTapped)) { $0.isChecking = true }
    await store.receive(\.checkResponse) {
      $0.isChecking = false
      $0.preview = preview
      $0.phase = .preview
    }
    await store.send(.view(.confirmTapped)) { $0.isChecking = true }
    await store.receive(\.registrationResponse) {
      $0.isChecking = false
      $0.registerNotice = .alreadyActive
      $0.customAlert = .ticketAlreadyActive()
    }
    #expect(store.state.phase == .preview)
  }
}

struct TicketStub: ClassTicketInterface {
  var preview: Result<ClassTicketPreview, ClassTicketError> = .failure(.invalidCode)
  var register: Result<ClassTicket, ClassTicketError> = .failure(.invalidCode)
  var myTicket: Result<ClassTicket, ClassTicketError> = .failure(.notFound)
  var myTicketFetch: (@Sendable () async throws -> ClassTicket)?
  var submittedCodes: LockIsolated<[String]>?

  func previewTicket(code: String) async throws -> ClassTicketPreview {
    submittedCodes?.withValue { $0.append(code) }
    return try preview.get()
  }

  func registerTicket(code: String) async throws -> ClassTicket {
    submittedCodes?.withValue { $0.append(code) }
    return try register.get()
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
