import ClassDomainInterface
import ComposableArchitecture
import Foundation
import PickeSharedUI

@Reducer
public struct ClassAIChatFeature {
  @Dependency(\.classAIChatUseCase) var chatUseCase

  public init() {}

  @ObservableState
  public struct State: Equatable {
    public let room: ClassRoom
    public let battleID: Int
    public let selectedOptionID: Int
    public var conversationID: UUID
    public var round = 1
    public var messages: [ClassAIChatMessage]
    public var draft = ""
    public var isGenerating = false
    public var isCompleted = false
    public var isModelAvailable = true
    public var errorMessage: String?
    public var hasStarted = false
    public var sessionRequestID: UUID?
    public var responseRequestID: UUID?
    public var pendingText: String?
    @Presents public var customAlert: CustomAlertState<CustomAlertAction>?

    public init(room: ClassRoom, battleID: Int, selectedOptionID: Int, conversationID: UUID = UUID()) {
      self.room = room
      self.battleID = battleID
      self.selectedOptionID = selectedOptionID
      self.conversationID = conversationID
      if room.battle.id == -1, selectedOptionID == 1 {
        messages = [
          .init(speaker: .opponent, text: "이건 기만입니다. 하늘 아래 모든 사물은 그에 걸맞은 완벽한 목적과 형상, 즉 '이데아'를 가지고 있습니다."),
          .init(speaker: .opponent, text: "변기의 이데아는 '배설물을 처리하는 것'이지, 감상하는 것이 아닙니다."),
          .init(speaker: .opponent, text: "사물의 본질을 왜곡하여 대중을 혼란에 빠뜨리는 것은 진리를 모독하는 행위입니다."),
        ]
      } else {
        messages = [
          .init(speaker: .opponent, text: "\(room.battle.title)라는 질문을 반대 입장에서 함께 생각해 볼까요?"),
        ]
      }
    }

    public var selectedStanceTitle: String {
      selectedOptionID == 1 ? room.battle.optionATitle : room.battle.optionBTitle
    }

    public var opponentName: String {
      return selectedOptionID == 1 ? room.battle.philosopherB : room.battle.philosopherA
    }

    public var opponentAvatarURL: URL? {
      selectedOptionID == 1 ? room.battle.philosopherBImageURL : room.battle.philosopherAImageURL
    }

    public var quickReplies: [String] {
      ["의미를 부여하는 건 인간이에요", "새로운 도구도 예술이 될 수 있어요", "AI는 결국 도구라고 봐요"]
    }
  }

  public enum Action: ViewAction {
    case view(View)
    case inner(InnerAction)
    case customAlert(PresentationAction<CustomAlertAction>)
    case delegate(DelegateAction)
  }

  @CasePathable
  public enum View: Equatable {
    case onAppear
    case onDisappear
    case backTapped
    case draftChanged(String)
    case quickReplyTapped(String)
    case sendTapped
    case finalVoteTapped
  }

  @CasePathable
  public enum InnerAction: Equatable {
    case sessionReady(UUID)
    case sessionFailed(UUID, String)
    case responseReceived(UUID, [String])
    case responseFailed(UUID, String)
  }

  @CasePathable
  public enum DelegateAction: Equatable {
    case dismiss
    case finalVote(battleID: Int)
  }

  enum CancelID {
    case session
    case response
  }

  public var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case let .view(viewAction):
        return handleViewAction(state: &state, action: viewAction)
      case let .inner(innerAction):
        return handleInnerAction(state: &state, action: innerAction)
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
