import BattleDomainInterface
import ClassDomainInterface
import ComposableArchitecture

@Reducer
public struct ClassAIVoteFeature {
  @Dependency(\.battleUseCase) private var battleUseCase

  public init() {}

  @ObservableState
  public struct State: Equatable {
    public let room: ClassRoom
    public let battleID: Int
    public var selectedOptionID: Int?
    public var hasSubmitted = false
    public var isSubmitting = false
    public var errorMessage: String?

    public init(room: ClassRoom, battleID: Int) {
      self.room = room
      self.battleID = battleID
    }

    public var canSubmit: Bool {
      selectedOptionID != nil && !isSubmitting
    }
  }

  public enum Action: ViewAction {
    case view(View)
    case inner(InnerAction)
    case delegate(DelegateAction)
  }

  @CasePathable
  public enum View: Equatable {
    case onAppear
    case backTapped
    case optionTapped(Int)
    case submitTapped
  }

  public enum InnerAction: Equatable {
    case voteLoaded(Result<UserVoteStatus, BattleError>)
    case voteSubmitted(Result<PreVoteResult, BattleError>)
  }

  @CasePathable
  public enum DelegateAction: Equatable {
    case dismiss
    case voteSubmitted(battleID: Int)
  }

  public var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .view(.onAppear):
        let battleID = state.battleID
        return .run { send in
          do {
            let status = try await battleUseCase.fetchBattle(battleId: battleID).userVoteStatus
            await send(.inner(.voteLoaded(.success(status))))
          } catch {
            await send(.inner(.voteLoaded(.failure(BattleError.from(error)))))
          }
        }

      case .view(.backTapped):
        return .send(.delegate(.dismiss))

      case let .view(.optionTapped(optionID)):
        guard !state.hasSubmitted, !state.isSubmitting, optionID == 1 || optionID == 2 else {
          return .none
        }
        state.selectedOptionID = optionID
        state.errorMessage = nil
        return .none

      case .view(.submitTapped):
        guard let optionID = state.selectedOptionID, !state.isSubmitting else { return .none }
        if state.hasSubmitted {
          return .send(.delegate(.voteSubmitted(battleID: state.battleID)))
        }
        state.isSubmitting = true
        state.errorMessage = nil
        let battleID = state.battleID
        return .run { send in
          do {
            let result = try await battleUseCase.submitPreVote(battleId: battleID, optionId: optionID)
            await send(.inner(.voteSubmitted(.success(result))))
          } catch {
            await send(.inner(.voteSubmitted(.failure(BattleError.from(error)))))
          }
        }

      case let .inner(.voteLoaded(.success(status))):
        switch status {
        case .pro:
          state.selectedOptionID = 1
          state.hasSubmitted = true
        case .con:
          state.selectedOptionID = 2
          state.hasSubmitted = true
        case .none, .unknown:
          break
        }
        return .none

      case .inner(.voteLoaded(.failure)):
        state.errorMessage = "투표 상태를 불러오지 못했어요. 다시 시도해 주세요."
        return .none

      case .inner(.voteSubmitted(.success)):
        state.isSubmitting = false
        state.hasSubmitted = true
        return .send(.delegate(.voteSubmitted(battleID: state.battleID)))

      case .inner(.voteSubmitted(.failure)):
        state.isSubmitting = false
        state.errorMessage = "투표를 저장하지 못했어요. 다시 시도해 주세요."
        return .none

      case .delegate:
        return .none
      }
    }
  }
}
