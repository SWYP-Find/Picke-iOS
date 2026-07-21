//
//  AttendanceModalFeature.swift
//  Home
//

import AttendanceDomainInterface
import ComposableArchitecture

@Reducer
public struct AttendanceModalFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public var weekly: WeeklyAttendance = .empty
    public var pointsEarned: Int = 0

    public init() {}
  }

  public enum Action: ViewAction {
    case view(View)
    case delegate(DelegateAction)
  }

  @CasePathable
  public enum View {
    case dismissTapped
  }

  public enum DelegateAction: Equatable {
    case dismissed
  }

  public var body: some Reducer<State, Action> {
    Reduce { _, action in
      switch action {
      case .view(.dismissTapped):
        return .send(.delegate(.dismissed))

      case .delegate:
        return .none
      }
    }
  }
}
