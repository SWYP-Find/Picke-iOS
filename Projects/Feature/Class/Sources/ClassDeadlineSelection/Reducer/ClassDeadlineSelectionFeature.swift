//
//  ClassDeadlineSelectionFeature.swift
//  Class
//
//  Created by Picke on 10/15/26.
//

import ComposableArchitecture
import Foundation

@Reducer
public struct ClassDeadlineSelectionFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public var settingInstanceID = UUID()
    public var draftDeadline = Date()
    public var minimumDate = Date()

    public init() {}

    // Preserve an expired draft in the wheel while confirmation remains invalid.
    public var minimumSelectableDate: Date { min(minimumDate, draftDeadline) }
    public var canConfirm: Bool { draftDeadline >= minimumDate }
    public var validationMessage: String? {
      return canConfirm ? nil : "현재 이후 시간을 선택해 주세요."
    }
    public var buttonTitle: String { "수정하기" }
  }

  public enum Action: ViewAction, BindableAction {
    case binding(BindingAction<State>)
    case view(View)
    case delegate(DelegateAction)
  }

  @CasePathable
  public enum View {
    case backTapped
    case confirmTapped
  }

  @CasePathable
  public enum DelegateAction: Equatable {
    case dismiss
    case confirmed(Date, settingInstanceID: UUID)
  }

  @Dependency(\.date) private var date

  public var body: some Reducer<State, Action> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .view(.backTapped):
        return .send(.delegate(.dismiss))
      case .view(.confirmTapped):
        state.minimumDate = date.now
        guard state.canConfirm else { return .none }
        return .send(.delegate(.confirmed(state.draftDeadline, settingInstanceID: state.settingInstanceID)))
      case .binding, .delegate:
        return .none
      }
    }
  }
}
