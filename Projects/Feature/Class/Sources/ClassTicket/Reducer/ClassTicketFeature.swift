//
//  ClassTicketFeature.swift
//  Class
//

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
    public var code = ""
    public var isChecking = false
    public var errorMessage: String?
    public var expandedFAQ: Int?
    public var registrationStartDate: Date?
    public var expirationDate: Date?

    public init(instanceID: UUID = UUID()) {
      self.instanceID = instanceID
    }

    public var canCheckCode: Bool {
      !code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isChecking
    }

    public var periodText: String {
      guard let registrationStartDate, let expirationDate else { return "" }
      return "\(registrationStartDate.formatted(.yearMonthDayDotted)) – \(expirationDate.formatted(.yearMonthDayDotted))"
    }
  }

  public enum Action: ViewAction, BindableAction {
    case binding(BindingAction<State>)
    case view(View)
    case checkResponse(Result<Date, ClassTicketCheckError>)
    case delegate(DelegateAction)
  }

  @CasePathable
  public enum View {
    case backTapped
    case checkTapped
    case confirmTapped
    case faqTapped(Int)
  }

  @CasePathable
  public enum DelegateAction: Equatable {
    case dismiss
  }

  public enum CancelID: Hashable, Sendable {
    case check(UUID)
  }

  @Dependency(\.continuousClock) private var clock
  @Dependency(\.date) private var date

  public var body: some Reducer<State, Action> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .binding(\.code):
        state.errorMessage = nil
        guard state.isChecking else { return .none }
        state.isChecking = false
        return .cancel(id: CancelID.check(state.instanceID))

      case .binding:
        return .none

      case .view(.backTapped), .view(.confirmTapped):
        return .send(.delegate(.dismiss))

      case let .view(.faqTapped(index)):
        state.expandedFAQ = state.expandedFAQ == index ? nil : index
        return .none

      case .view(.checkTapped):
        guard state.phase == .entry, state.canCheckCode else { return .none }
        state.isChecking = true
        state.errorMessage = nil
        let submittedCode = state.code.trimmingCharacters(in: .whitespacesAndNewlines)
        return .run { [clock, date] send in
          try await clock.sleep(for: .milliseconds(350))
          let result: Result<Date, ClassTicketCheckError> = submittedCode == "PICKE30"
            ? .success(date.now)
            : .failure(.invalidCode)
          await send(.checkResponse(result))
        }
        .cancellable(id: CancelID.check(state.instanceID), cancelInFlight: true)

      case let .checkResponse(result):
        guard state.phase == .entry, state.isChecking else { return .none }
        state.isChecking = false
        switch result {
        case let .success(registeredAt):
          let calendar = AppDateFormat.calendar
          let start = calendar.startOfDay(for: registeredAt)
          guard
            let sixMonthsLater = calendar.date(byAdding: .month, value: 6, to: start),
            let lastDay = calendar.date(byAdding: .day, value: -1, to: sixMonthsLater)
          else { return .none }
          state.registrationStartDate = start
          state.expirationDate = lastDay
          state.phase = .registered

        case .failure:
          state.errorMessage = "유효하지 않은 이용권 코드예요. 다시 확인해 주세요."
        }
        return .none

      case .delegate:
        return .none
      }
    }
  }
}
