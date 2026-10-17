//
//  ClassFeedbackComposeFeature.swift
//  Class
//
//  Created by Picke on 10/11/26.
//

import ClassDomainInterface
import ComposableArchitecture
import Foundation
import PickeSharedUI

@Reducer
public struct ClassFeedbackComposeFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public let room: ClassRoom
    public let memberName: String
    public var feedback = ""
    @Presents public var customAlert: CustomAlertState<CustomAlertAction>?

    public init(
      room: ClassRoom,
      memberName: String
    ) {
      self.room = room
      self.memberName = memberName
    }
  }

  public enum Action: ViewAction, BindableAction {
    case binding(BindingAction<State>)
    case view(View)
    case customAlert(PresentationAction<CustomAlertAction>)
    case delegate(DelegateAction)
  }

  @CasePathable
  public enum View: Equatable {
    case backTapped
    case cancelTapped
    case submitTapped
  }

  @CasePathable
  public enum DelegateAction: Equatable {
    case dismiss
    case submitted(String)
  }

  public var body: some Reducer<State, Action> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .binding:
        return .none
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

extension ClassFeedbackComposeFeature {
  private func handleViewAction(
    state: inout State,
    action: View
  ) -> Effect<Action> {
    switch action {
    case .backTapped, .cancelTapped:
      return .send(.delegate(.dismiss))
    case .submitTapped:
      let feedback = state.feedback.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !feedback.isEmpty else { return .none }
      state.customAlert = .alert(
        title: "전송 준비 중",
        message: "서버 연동 전이라 피드백을 전송할 수 없습니다.",
        cancelTitle: ""
      )
      return .none
    }
  }

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
}
