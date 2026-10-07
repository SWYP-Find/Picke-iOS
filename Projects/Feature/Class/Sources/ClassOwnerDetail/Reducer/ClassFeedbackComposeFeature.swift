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

    public init(room: ClassRoom, memberName: String) {
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
      case .view(.backTapped), .view(.cancelTapped):
        return .send(.delegate(.dismiss))
      case .view(.submitTapped):
        let feedback = state.feedback.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !feedback.isEmpty else { return .none }
        state.customAlert = .alert(
          title: "전송 준비 중",
          message: "서버 연동 전이라 피드백을 전송할 수 없습니다.",
          cancelTitle: ""
        )
        return .none
      case .customAlert(.presented(.confirmTapped)),
           .customAlert(.presented(.cancelTapped)),
           .customAlert(.dismiss):
        state.customAlert = nil
        return .none
      case .customAlert:
        return .none
      case .delegate:
        return .none
      }
    }
    .ifLet(\.$customAlert, action: \.customAlert) {
      CustomConfirmAlert()
    }
  }
}
