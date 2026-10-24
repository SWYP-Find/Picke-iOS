//
//  ClassShareFeature.swift
//  Class
//
//  Created by Picke on 10/11/26.
//

import ClassDomainInterface
import ComposableArchitecture
import Foundation
import PickeCoreUtility

@Reducer
public struct ClassShareFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public var room: ClassRoom

    public init(room: ClassRoom) {
      self.room = room
    }

    /// 마감일을 끈 클래스는 `.distantFuture` 로 만들어지므로 표시하지 않는다.
    public var deadlineText: String? {
      guard room.deadline != .distantFuture else { return nil }
      return "참여 마감 · \(room.deadline.formatted(.fullKoreanDateTime))"
    }

    public var shareMessage: String {
      "[Picke] '\(room.name)' 클래스에 참여해 주세요!\n참여 코드: \(room.joinCode)"
    }
  }

  public enum Action: ViewAction {
    case view(View)
    case delegate(DelegateAction)
  }

  @CasePathable
  public enum View {
    case closeTapped
    case enterClassTapped
  }

  @CasePathable
  public enum DelegateAction: Equatable {
    case dismiss
    case nameOwner(ClassRoom)
    case enterClass(ClassRoom)
  }

  public var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case let .view(viewAction):
        return handleViewAction(state: &state, action: viewAction)

      case .delegate:
        return .none
      }
    }
  }
}

// MARK: - Action Handlers

extension ClassShareFeature {
  private func handleViewAction(
    state: inout State,
    action: View
  ) -> Effect<Action> {
    switch action {
    case .closeTapped:
      return .send(.delegate(.dismiss))

    case .enterClassTapped:
      return state.room.ownerParticipates
        ? .send(.delegate(.nameOwner(state.room)))
        : .send(.delegate(.enterClass(state.room)))
    }
  }
}
