//
//  BattleProposalFeature.swift
//  Profile
//

import Foundation

import ComposableArchitecture
import PickeDesignKit
import PickeSharedUI
import BattleDomainInterface
import LogMacro

@Reducer
public struct BattleProposalFeature {
  public init() {}

  static let descriptionLimit = 200

  @ObservableState
  public struct State: Equatable {
    public var selectedCategory: BattleProposalCategory = .philosophy
    public var topic: String = ""
    public var positionA: String = ""
    public var positionB: String = ""
    public var description: String = ""
    public var isSubmitting: Bool = false
    @Presents public var customAlert: CustomAlertState<CustomAlertAction>?

    public init() {}

    /// 필수 항목(주제/양측 입장) 충족 시 제안 가능.
    public var isSubmitEnabled: Bool {
      !topic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && !positionA.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && !positionB.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && !isSubmitting
    }
  }

  public enum Action: ViewAction, BindableAction {
    case binding(BindingAction<State>)
    case view(View)
    case async(AsyncAction)
    case inner(InnerAction)
    case scope(ScopeAction)
    case delegate(DelegateAction)
  }

  @CasePathable
  public enum ScopeAction: Equatable {
    case customAlert(PresentationAction<CustomAlertAction>)
  }

  @CasePathable
  public enum View {
    case backTapped
    case categorySelected(BattleProposalCategory)
    case submitTapped
  }

  public enum AsyncAction: Equatable {
    case submit
  }

  public enum InnerAction: Equatable {
    case submitResponse(Result<BattleProposal, BattleError>)
  }

  public enum DelegateAction: Equatable {
    case dismiss
    /// 제안 성공 → 화면 닫기.
    case proposed(BattleProposal)
  }

  nonisolated enum CancelID: Hashable {
    case submit
  }

  @Dependency(\.battleUseCase) private var battleUseCase

  public var body: some Reducer<State, Action> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .binding:
        // 부가 설명 200자 제한.
        if state.description.count > Self.descriptionLimit {
          state.description = String(state.description.prefix(Self.descriptionLimit))
        }
        return .none

      case let .view(viewAction):
        return handleViewAction(state: &state, action: viewAction)

      case let .async(asyncAction):
        return handleAsyncAction(state: &state, action: asyncAction)

      case let .inner(innerAction):
        return handleInnerAction(state: &state, action: innerAction)

      case let .scope(scopeAction):
        return handleScopeAction(state: &state, action: scopeAction)

      case let .delegate(delegateAction):
        return handleDelegateAction(state: &state, action: delegateAction)
      }
    }
    .ifLet(\.$customAlert, action: \.scope.customAlert) {
      CustomConfirmAlert()
    }
  }
}

extension BattleProposalFeature {
  private func handleViewAction(
    state: inout State,
    action: View
  ) -> Effect<Action> {
    switch action {
    case .backTapped:
      return .send(.delegate(.dismiss))

    case let .categorySelected(category):
      state.selectedCategory = category
      return .none

    case .submitTapped:
      guard state.isSubmitEnabled else { return .none }
      return .send(.async(.submit))
    }
  }

  private func handleAsyncAction(
    state: inout State,
    action: AsyncAction
  ) -> Effect<Action> {
    switch action {
    case .submit:
      state.isSubmitting = true
      let draft = BattleProposalDraft(
        category: state.selectedCategory.title,
        topic: state.topic,
        positionA: state.positionA,
        positionB: state.positionB,
        description: state.description
      )
      return .run { [useCase = battleUseCase] send in
        let result = await Result {
          try await useCase.proposeBattle(draft)
        }
        .mapError(BattleError.from)
        return await send(.inner(.submitResponse(result)))
      }
      .cancellable(id: CancelID.submit, cancelInFlight: true)
    }
  }

  private func handleInnerAction(
    state: inout State,
    action: InnerAction
  ) -> Effect<Action> {
    switch action {
    case let .submitResponse(result):
      state.isSubmitting = false
      switch result {
      case .success:
        // 제안 성공 → 완료 팝업 노출 (확인 시 화면 닫음).
        state.customAlert = .alert(
          title: "제안이 완료되었어요",
          message: "검토 후 배틀로 등록되면 알려드릴게요",
          confirmTitle: "확인",
          cancelTitle: ""
        )
        return .none
      case let .failure(error):
        Log.error("[BattleProposalFeature] proposeBattle failed: \(error.localizedDescription)")
        return .none
      }
    }
  }

  private func handleScopeAction(
    state: inout State,
    action: ScopeAction
  ) -> Effect<Action> {
    switch action {
    case let .customAlert(alertAction):
      switch alertAction {
      case .presented(.confirmTapped):
        state.customAlert = nil
        return .send(.delegate(.dismiss))
      case .presented(.cancelTapped):
        state.customAlert = nil
        return .none
      case .dismiss:
        state.customAlert = nil
        return .none
      }
    }
  }

  private func handleDelegateAction(
    state _: inout State,
    action: DelegateAction
  ) -> Effect<Action> {
    switch action {
    case .dismiss:
      return .none
    case .proposed:
      return .none
    }
  }
}
