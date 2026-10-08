//
//  ClassSettingFeature.swift
//  Class
//

import ClassDomainInterface
import ComposableArchitecture
import Foundation
import PickeSharedUI

@Reducer
public struct ClassSettingFeature {
  @Dependency(\.classUseCase) private var classUseCase

  public init() {}

  @ObservableState
  public struct State: Equatable {
    public var battle: ClassBattleSummary?
    public var aiQuestion: ClassAIQuestion?
    public var name = ""
    public var deadline: Date
    public var isDeadlineEnabled = true
    public var isDatePickerPresented = false
    public var requiresComment = false
    public var isLoading = false
    public var errorMessage: String?
    @Presents public var unavailableNotice: ClassAIUnavailableNoticeFeature.State?
    @Presents public var customAlert: CustomAlertState<CustomAlertAction>?

    public init(
      battle: ClassBattleSummary,
      deadline: Date = Date().addingTimeInterval(7 * 24 * 60 * 60)
    ) {
      self.battle = battle
      self.deadline = deadline
    }

    public init(
      aiQuestion: ClassAIQuestion,
      deadline: Date = Date().addingTimeInterval(7 * 24 * 60 * 60)
    ) {
      self.aiQuestion = aiQuestion
      self.deadline = deadline
    }

    public var deadlineText: String {
      Self.deadlineFormatter.string(from: deadline)
    }

    public var canCreate: Bool {
      !trimmedName.isEmpty && !isLoading
    }

    public var creation: ClassCreation? {
      guard let battle else { return nil }
      return ClassCreation(
        name: trimmedName,
        deadline: isDeadlineEnabled ? deadline : .distantFuture,
        battleId: battle.id,
        allowsAnonymousOpinion: false,
        requiresComment: requiresComment
      )
    }

    private var trimmedName: String {
      name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static let deadlineFormatter: DateFormatter = {
      let formatter = DateFormatter()
      formatter.locale = Locale(identifier: "ko_KR")
      formatter.dateFormat = "yyyy년 MM월 dd일 HH:mm"
      return formatter
    }()
  }

  public enum Action: ViewAction, BindableAction {
    case binding(BindingAction<State>)
    case view(View)
    case async(AsyncAction)
    case inner(InnerAction)
    case delegate(DelegateAction)
    case unavailableNotice(PresentationAction<ClassAIUnavailableNoticeFeature.Action>)
    case customAlert(PresentationAction<CustomAlertAction>)
  }

  @CasePathable
  public enum View {
    case backTapped
    case deadlineFieldTapped
    case createTapped
  }

  public enum AsyncAction: Equatable {
    case create(ClassCreation)
  }

  @CasePathable
  public enum InnerAction: Equatable {
    case created(Result<ClassRoom, ClassError>)
  }

  @CasePathable
  public enum DelegateAction: Equatable {
    case dismiss
    case created(ClassRoom)
  }

  nonisolated enum CancelID: Hashable {
    case create
  }

  public var body: some Reducer<State, Action> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .binding:
        return .none

      case .unavailableNotice(.presented(.dismissTapped)):
        state.unavailableNotice = nil
        return .none

      case .unavailableNotice:
        return .none

      case .customAlert(.presented(.confirmTapped)),
           .customAlert(.presented(.cancelTapped)),
           .customAlert(.dismiss):
        state.customAlert = nil
        state.errorMessage = nil
        return .none

      case .customAlert:
        return .none

      case let .view(viewAction):
        return handleViewAction(state: &state, action: viewAction)

      case let .async(asyncAction):
        return handleAsyncAction(state: &state, action: asyncAction)

      case let .inner(innerAction):
        return handleInnerAction(state: &state, action: innerAction)

      case .delegate:
        return .none
      }
    }
    .ifLet(\.$unavailableNotice, action: \.unavailableNotice) {
      ClassAIUnavailableNoticeFeature()
    }
    .ifLet(\.$customAlert, action: \.customAlert) {
      CustomConfirmAlert()
    }
  }
}

extension ClassSettingFeature {
  private func handleViewAction(
    state: inout State,
    action: View
  ) -> Effect<Action> {
    switch action {
    case .backTapped:
      return .send(.delegate(.dismiss))

    case .deadlineFieldTapped:
      state.isDatePickerPresented.toggle()
      return .none

    case .createTapped:
      guard state.canCreate else { return .none }
      if state.aiQuestion != nil {
        state.unavailableNotice = .init()
        return .none
      }
      guard let creation = state.creation else { return .none }
      return .send(.async(.create(creation)))
    }
  }

  private func handleAsyncAction(
    state: inout State,
    action: AsyncAction
  ) -> Effect<Action> {
    switch action {
    case let .create(creation):
      state.isLoading = true
      state.errorMessage = nil
      return .run { [classUseCase] send in
        let result = await Result {
          try await classUseCase.createClass(creation)
        }
        .mapError(ClassError.from)
        await send(.inner(.created(result)))
      }
      .cancellable(id: CancelID.create, cancelInFlight: true)
    }
  }

  private func handleInnerAction(
    state: inout State,
    action: InnerAction
  ) -> Effect<Action> {
    switch action {
    case let .created(result):
      state.isLoading = false
      switch result {
      case let .success(room):
        return .send(.delegate(.created(room)))
      case let .failure(error):
        state.errorMessage = error.localizedDescription
        state.customAlert = .alert(
          title: "클래스를 만들지 못했어요",
          message: error.localizedDescription
        )
        return .none
      }
    }
  }
}
