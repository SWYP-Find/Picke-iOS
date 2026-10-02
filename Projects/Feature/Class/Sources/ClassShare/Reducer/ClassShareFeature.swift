//
//  ClassShareFeature.swift
//  Class
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

    public init(room: ClassRoom) {
      self.room = room
    }

    /// 마감일을 끈 클래스는 `.distantFuture` 로 만들어지므로 표시하지 않는다.
    public var deadlineText: String? {
      guard room.deadline != .distantFuture else { return nil }
      return "참여 마감  \(Self.deadlineFormatter.string(from: room.deadline))"
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

  public var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .view(.closeTapped):
        return .send(.delegate(.dismiss))

      case .view(.enterClassTapped):
        return .send(.delegate(.enterClass(state.room)))

      case .delegate:
        return .none
      }
    }
  }
}
