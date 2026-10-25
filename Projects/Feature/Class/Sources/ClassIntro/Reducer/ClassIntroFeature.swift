//
//  ClassIntroFeature.swift
//  Class
//
//  Created by Picke on 10/11/26.
//

import ComposableArchitecture
import Foundation
import PickeSharedUI

@Reducer
public struct ClassIntroFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    @Presents public var customAlert: CustomAlertState<CustomAlertAction>?

    public init() {}
  }

  public enum Action: ViewAction {
    case view(View)
    case customAlert(PresentationAction<CustomAlertAction>)
    case delegate(DelegateAction)
  }

  @CasePathable
  public enum View {
    case backTapped
    case joinTapped
    case myClassesTapped
    case createTapped
    case ticketTapped
  }

  @CasePathable
  public enum DelegateAction: Equatable {
    case backToHome
    case join
    case myClasses
    case create
    case ticket
  }

  public var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case let .view(viewAction):
        return handleViewAction(state: &state, action: viewAction)

      case let .customAlert(alertAction):
        return handleCustomAlertAction(state: &state, action: alertAction)

      case .delegate:
        return .none
      }
    }
    .ifLet(\.$customAlert, action: \.customAlert) {
      CustomConfirmAlert()
    }
  }
}

// MARK: - Action Handlers

extension ClassIntroFeature {
  private func handleCustomAlertAction(
    state: inout State,
    action: PresentationAction<CustomAlertAction>
  ) -> Effect<Action> {
    switch action {
    case .presented(.confirmTapped), .presented(.cancelTapped), .dismiss:
      state.customAlert = nil
      return .none
    case .presented:
      return .none
    }
  }

  private func handleViewAction(
    state: inout State,
    action: View
  ) -> Effect<Action> {
    switch action {
    case .backTapped:
      return .send(.delegate(.backToHome))

    case .joinTapped:
      return .send(.delegate(.join))

    case .myClassesTapped:
      return .send(.delegate(.myClasses))

    case .createTapped:
      return .send(.delegate(.create))

    case .ticketTapped:
      return .send(.delegate(.ticket))
    }
  }
}
