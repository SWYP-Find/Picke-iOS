//
//  ClassTicketFeature.swift
//  Class
//

import ClassDomainInterface
import ComposableArchitecture
import Foundation
import PickeCoreUtility
import PickeSharedUI

@Reducer
public struct ClassTicketFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public var instanceID = UUID()
    public var phase: ClassTicketPhase = .entry
    public var shouldCheckExistingTicket = true
    public var code = ""
    public var isChecking = false
    public var isLoadingExistingTicket = false
    public var expandedFAQ: Int?
    public var preview: ClassTicketPreview?
    public var ticket: ClassTicket?
    public var registrationStartDate: Date?
    public var expirationDate: Date?
    @Presents public var customAlert: CustomAlertState<CustomAlertAction>?
    public var registerNotice: ClassTicketRegisterNotice?
    public var toastMessage: String?
    public var closesAfterToast = false

    public init(instanceID: UUID = UUID()) {
      self.instanceID = instanceID
    }

    /// Android와 같이 대문자로 바꾸고 영문·숫자·`-`만 남긴다(서버도 공백·하이픈·대소문자를 무시).
    public var normalizedCode: String {
      // 글자 묶음이 아니라 유니코드 단위로 걸러 ASCII만 남긴다(예: "1️⃣", "A̲"의 결합 문자 제거).
      let scalars = code.uppercased().unicodeScalars.filter { scalar in
        ("A"..."Z").contains(scalar) || ("0"..."9").contains(scalar) || scalar == "-"
      }
      return String(scalars)
    }

    public var canCheckCode: Bool {
      !normalizedCode.isEmpty && !isChecking && !isLoadingExistingTicket
    }

    public var navigationTitle: String {
      phase == .overview ? "클래스 이용권" : "이용권 등록하기"
    }

    public var capacity: Int? {
      ticket?.capacity ?? preview?.capacity
    }

    public var ticketTitle: String {
      capacity.map { "클래스 \($0)인 이용권" } ?? "클래스 이용권"
    }

    /// 개요는 사용 중(ACTIVE) 이용권만 보여 준다(만료면 코드 입력).
    public var overviewTitle: String {
      "사용 중인 이용권"
    }

    public var capacityDetail: String {
      capacity.map { "클래스당 최대 \($0)명" } ?? "정원 정보 없음"
    }

    public var ticketPeriodText: String {
      if phase == .preview, let preview {
        return "등록일부터 \(preview.usageMonths)개월"
      }
      return periodText
    }

    public var canRegister: Bool {
      phase == .preview && preview != nil && !isChecking
    }

    public var primaryButtonTitle: String {
      if isChecking || isLoadingExistingTicket { return "처리 중..." }
      switch phase {
      case .entry: return "코드 확인하기"
      case .preview: return "이용권 등록하기"
      case .registered, .overview: return "이용권 확인하기"
      }
    }

    public var periodText: String {
      guard let registrationStartDate, let expirationDate else { return "" }
      return "\(registrationStartDate.formatted(.yearMonthDayDotted)) – \(expirationDate.formatted(.yearMonthDayDotted))"
    }
  }

  public enum Action: ViewAction, BindableAction {
    case binding(BindingAction<State>)
    case view(View)
    case customAlert(PresentationAction<CustomAlertAction>)
    case checkResponse(Result<ClassTicketPreview, ClassTicketError>)
    case registrationResponse(Result<ClassTicket, ClassTicketError>)
    /// 화면 진입 시 내 이용권 조회 결과.
    case existingTicketResponse(Result<ClassTicket, ClassTicketError>)
    /// 내가 등록한 코드를 다시 입력했을 때 내 이용권 조회 결과.
    case registeredTicketResponse(Result<ClassTicket, ClassTicketError>)
    case delegate(DelegateAction)
  }

  @CasePathable
  public enum View {
    case onAppear
    case backTapped
    case checkTapped
    case confirmTapped
    case addRegistrationTapped
    case faqTapped(Int)
    case toastShown
  }

  @CasePathable
  public enum DelegateAction: Equatable {
    case dismiss
    case registrationConfirmed(startDate: Date, endDate: Date)
    case addRegistrationRequested
    case registered(Date, Date)
    /// 내가 등록한 사용 중 이용권을 다시 입력함. 코디네이터가 기존 개요로 돌아가거나 이 화면을 개요로 바꾼다.
    case existingTicketFound(ClassTicket)
  }

  public enum CancelID: Hashable, Sendable {
    case check(UUID)
    case existingTicket(UUID)
  }

  @Dependency(\.classTicketUseCase) private var ticketUseCase

  public var body: some Reducer<State, Action> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .binding(\.code):
        let wasLookingUpRegisteredTicket = state.preview != nil && state.isLoadingExistingTicket
        state.preview = nil
        if wasLookingUpRegisteredTicket {
          state.isLoadingExistingTicket = false
          return .cancel(id: CancelID.existingTicket(state.instanceID))
        }
        guard state.isChecking else { return .none }
        state.isChecking = false
        return .cancel(id: CancelID.check(state.instanceID))

      case .binding:
        return .none

      case .view(.onAppear):
        guard state.phase == .entry,
              state.shouldCheckExistingTicket,
              state.ticket == nil,
              state.preview == nil,
              !state.isLoadingExistingTicket
        else { return .none }
        state.shouldCheckExistingTicket = false
        state.isLoadingExistingTicket = true
        return fetchMyTicket(state: state) { .existingTicketResponse($0) }

      case .view(.backTapped):
        // Android와 같이 확인 단계에서는 코드 입력으로 돌아간다. 등록 요청 중에는 무시한다.
        if state.phase == .preview {
          guard !state.isChecking else { return .none }
          state.phase = .entry
          state.preview = nil
          return .none
        }
        return .send(.delegate(.dismiss))

      case .view(.confirmTapped):
        if state.phase == .preview {
          guard state.canRegister else { return .none }
          state.isChecking = true
          let submittedCode = state.normalizedCode
          return .run { [ticketUseCase] send in
            let result: Result<ClassTicket, ClassTicketError> = await Result {
              try await ticketUseCase.registerTicket(code: submittedCode)
            }
            .mapError(Self.mapError)
            await send(.registrationResponse(result))
          }
          .cancellable(id: CancelID.check(state.instanceID), cancelInFlight: true)
        }
        guard
          state.phase == .registered,
          let registrationStartDate = state.registrationStartDate,
          let expirationDate = state.expirationDate
        else { return .none }
        return .send(.delegate(.registrationConfirmed(
          startDate: registrationStartDate,
          endDate: expirationDate
        )))

      case .view(.addRegistrationTapped):
        guard state.phase == .overview else { return .none }
        return .send(.delegate(.addRegistrationRequested))

      case let .view(.faqTapped(index)):
        state.expandedFAQ = state.expandedFAQ == index ? nil : index
        return .none

      case .view(.checkTapped):
        guard state.phase == .entry, state.canCheckCode else { return .none }
        state.isChecking = true
        let submittedCode = state.normalizedCode
        return .run { [ticketUseCase] send in
          let result: Result<ClassTicketPreview, ClassTicketError> = await Result {
            try await ticketUseCase.previewTicket(code: submittedCode)
          }
          .mapError(Self.mapError)
          await send(.checkResponse(result))
        }
        .cancellable(id: CancelID.check(state.instanceID), cancelInFlight: true)

      case .view(.toastShown):
        state.toastMessage = nil
        // 토스트를 띄운 뒤에 닫아야 사라지는 화면에서도 안내가 보인다.
        guard state.closesAfterToast else { return .none }
        state.closesAfterToast = false
        return .send(.delegate(.dismiss))

      case .customAlert(.presented(.confirmTapped)):
        let notice = state.registerNotice
        clearRegisterNotice(state: &state)
        return notice == .alreadyRegistered ? .send(.delegate(.dismiss)) : .none

      case .customAlert(.presented(.cancelTapped)), .customAlert(.dismiss):
        clearRegisterNotice(state: &state)
        return .none

      case .customAlert:
        return .none

      case let .checkResponse(result):
        guard state.phase == .entry, state.isChecking else { return .none }
        state.isChecking = false
        switch result {
        case let .success(preview):
          state.preview = preview
          if preview.registeredByMe {
            // Android와 같이 내 이용권 상태를 확인해 사용 중이면 이용권 화면, 아니면 만료 안내.
            state.isLoadingExistingTicket = true
            return fetchMyTicket(state: state) { .registeredTicketResponse($0) }
          }
          state.phase = .preview
        case let .failure(error):
          presentRegisterNotice(.init(error: error), state: &state)
        }
        return .none

      case let .registrationResponse(result):
        guard state.phase == .preview, state.isChecking else { return .none }
        state.isChecking = false
        switch result {
        case let .success(ticket):
          state.ticket = ticket
          state.registrationStartDate = ticket.activatedAt
          state.expirationDate = ticket.expiresAt
          state.phase = .registered
          return .send(.delegate(.registered(ticket.activatedAt, ticket.expiresAt)))
        case let .failure(error):
          presentRegisterNotice(.init(error: error), state: &state)
        }
        return .none

      case let .existingTicketResponse(result):
        guard state.phase == .entry, state.isLoadingExistingTicket else { return .none }
        state.isLoadingExistingTicket = false
        switch result {
        case let .success(ticket) where ticket.status == .active:
          state.ticket = ticket
          state.registrationStartDate = ticket.activatedAt
          state.expirationDate = ticket.expiresAt
          state.phase = .overview
        case .success, .failure(.notFound):
          // 만료됐거나 없으면 Android와 같이 코드 입력부터 시작한다.
          break
        case .failure:
          state.toastMessage = "정보를 불러오지 못했어요"
          state.closesAfterToast = true
        }
        return .none

      case let .registeredTicketResponse(result):
        // 코드를 고치면 preview가 비므로 늦게 온 결과는 무시된다.
        guard state.phase == .entry, state.isLoadingExistingTicket, state.preview != nil else { return .none }
        state.isLoadingExistingTicket = false
        switch result {
        case let .success(ticket) where ticket.status == .active:
          return .send(.delegate(.existingTicketFound(ticket)))
        case .success:
          presentRegisterNotice(.registrationExpired, state: &state)
        case let .failure(error):
          presentRegisterNotice(.init(error: error), state: &state)
        }
        return .none

      case .delegate:
        return .none
      }
    }
    .ifLet(\.$customAlert, action: \.customAlert) {
      CustomConfirmAlert()
    }
  }

  private func fetchMyTicket(
    state: State,
    response: @escaping @Sendable (Result<ClassTicket, ClassTicketError>) -> Action
  ) -> Effect<Action> {
    .run { [ticketUseCase] send in
      let result: Result<ClassTicket, ClassTicketError> = await Result {
        try await ticketUseCase.fetchMyTicket()
      }
      .mapError(Self.mapError)
      await send(response(result))
    }
    .cancellable(id: CancelID.existingTicket(state.instanceID), cancelInFlight: true)
  }

  private func presentRegisterNotice(
    _ notice: ClassTicketRegisterNotice,
    state: inout State
  ) {
    state.registerNotice = notice
    state.customAlert = notice.alert
  }

  private func clearRegisterNotice(state: inout State) {
    state.registerNotice = nil
    state.customAlert = nil
  }

  private static func mapError(_ error: Error) -> ClassTicketError {
    (error as? ClassTicketError) ?? .network(error.localizedDescription)
  }
}
