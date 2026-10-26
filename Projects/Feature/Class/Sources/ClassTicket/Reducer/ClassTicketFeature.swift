//
//  ClassTicketFeature.swift
//  Class
//

import ClassDomainInterface
import ComposableArchitecture
import Foundation
import PickeCoreUtility

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
    public var errorMessage: String?
    public var expandedFAQ: Int?
    public var preview: ClassTicketPreview?
    public var ticket: ClassTicket?
    public var registrationStartDate: Date?
    public var expirationDate: Date?

    public init(instanceID: UUID = UUID()) {
      self.instanceID = instanceID
    }

    public var canCheckCode: Bool {
      !code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isChecking && !isLoadingExistingTicket
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

    public var overviewTitle: String {
      ticket?.status == .expired ? "만료된 이용권" : "사용 중인 이용권"
    }

    public var capacityDetail: String {
      capacity.map { "클래스당 최대 \($0)명" } ?? "정원 정보 없음"
    }

    public var ticketPeriodText: String {
      if phase == .preview, let preview {
        return "등록 후 \(preview.usageMonths)개월"
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
    case checkResponse(Result<ClassTicketPreview, ClassTicketError>)
    case registrationResponse(Result<ClassTicket, ClassTicketError>)
    case myTicketResponse(Result<ClassTicket, ClassTicketError>)
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
  }

  @CasePathable
  public enum DelegateAction: Equatable {
    case dismiss
    case registrationConfirmed(startDate: Date, endDate: Date)
    case addRegistrationRequested
    case registered(Date, Date)
  }

  public enum CancelID: Hashable, Sendable {
    case check(UUID)
    case existingTicket(UUID)
  }

  @Dependency(\.classUseCase) private var ticketUseCase

  public var body: some Reducer<State, Action> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .binding(\.code):
        state.errorMessage = nil
        state.preview = nil
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
        return .run { [ticketUseCase] send in
          let result: Result<ClassTicket, ClassTicketError> = await Result {
            try await ticketUseCase.fetchMyTicket()
          }
          .mapError(Self.mapError)
          await send(.myTicketResponse(result))
        }
        .cancellable(id: CancelID.existingTicket(state.instanceID), cancelInFlight: true)

      case .view(.backTapped):
        return .send(.delegate(.dismiss))

      case .view(.confirmTapped):
        if state.phase == .preview {
          guard state.canRegister else { return .none }
          state.isChecking = true
          state.errorMessage = nil
          let submittedCode = state.code.trimmingCharacters(in: .whitespacesAndNewlines)
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
        state.errorMessage = nil
        let submittedCode = state.code.trimmingCharacters(in: .whitespacesAndNewlines)
        return .run { [ticketUseCase] send in
          let result: Result<ClassTicketPreview, ClassTicketError> = await Result {
            try await ticketUseCase.previewTicket(code: submittedCode)
          }
          .mapError(Self.mapError)
          await send(.checkResponse(result))
        }
        .cancellable(id: CancelID.check(state.instanceID), cancelInFlight: true)

      case let .checkResponse(result):
        guard state.phase == .entry, state.isChecking else { return .none }
        state.isChecking = false
        switch result {
        case let .success(preview):
          state.preview = preview
          if preview.registeredByMe {
            state.isLoadingExistingTicket = true
            return .run { [ticketUseCase] send in
              let result: Result<ClassTicket, ClassTicketError> = await Result {
                try await ticketUseCase.fetchMyTicket()
              }
              .mapError(Self.mapError)
              await send(.myTicketResponse(result))
            }
            .cancellable(id: CancelID.existingTicket(state.instanceID), cancelInFlight: true)
          }
          state.phase = .preview
        case let .failure(error):
          state.errorMessage = error.message
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
          state.errorMessage = error.message
        }
        return .none

      case let .myTicketResponse(result):
        guard state.phase == .entry, state.isLoadingExistingTicket else { return .none }
        state.isLoadingExistingTicket = false
        switch result {
        case let .success(ticket):
          state.ticket = ticket
          state.registrationStartDate = ticket.activatedAt
          state.expirationDate = ticket.expiresAt
          state.phase = .overview
        case let .failure(error):
          if error != .notFound {
            state.errorMessage = error.message
          }
        }
        return .none

      case .delegate:
        return .none
      }
    }
  }

  private static func mapError(_ error: Error) -> ClassTicketError {
    (error as? ClassTicketError) ?? .network(error.localizedDescription)
  }
}
