//
//  ClassShareFeature.swift
//  Class
//
//  Created by Picke on 10/11/26.
//

import ClassDomainInterface
import ComposableArchitecture
import Foundation

@Reducer
public struct ClassShareFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public var room: ClassRoom
    @Presents public var join: ClassJoinFeature.State?

    public init(room: ClassRoom) {
      self.room = room
    }

    /// 마감일을 끈 클래스는 `.distantFuture` 로 만들어지므로 표시하지 않는다.
    public var deadlineText: String? {
      guard room.deadline != .distantFuture else { return nil }
      return "참여 마감 · \(Self.deadlineFormatter.string(from: room.deadline))"
    }

    public var shareMessage: String {
      "[Picke] '\(room.name)' 클래스에 참여해 주세요!\n참여 코드: \(room.joinCode)"
    }

    private static let deadlineFormatter: DateFormatter = {
      let formatter = DateFormatter()
      formatter.locale = Locale(identifier: "ko_KR")
      formatter.dateFormat = "yyyy년 MM월 dd일 HH:mm"
      return formatter
    }()
  }

  public enum Action: ViewAction {
    case view(View)
    case join(PresentationAction<ClassJoinFeature.Action>)
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
    case enterClass(ClassRoom)
  }

  @Dependency(\.classMockRepository) private var classMockRepository

  public var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case let .view(viewAction):
        return handleViewAction(state: &state, action: viewAction)

      case let .join(joinAction):
        return handleJoinAction(state: &state, action: joinAction)

      case .delegate:
        return .none
      }
    }
    .ifLet(\.$join, action: \.join) {
      ClassJoinFeature()
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
      guard classMockRepository != nil else {
        return .send(.delegate(.enterClass(state.room)))
      }
      state.join = .init(mode: .ownerName, preview: state.room)
      return .none
    }
  }

  private func handleJoinAction(
    state: inout State,
    action: PresentationAction<ClassJoinFeature.Action>
  ) -> Effect<Action> {
    switch action {
    case .presented(.delegate(.dismiss)):
      state.join = nil
      return .none

    case let .presented(.delegate(.ownerNamed(room))):
      state.join = nil
      return .send(.delegate(.enterClass(room)))

    case .presented, .dismiss:
      return .none
    }
  }
}
