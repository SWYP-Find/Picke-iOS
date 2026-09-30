//
//  ClassSettingFeature.swift
//  Class
//

import ClassDomainInterface
import ComposableArchitecture
import Foundation

@Reducer
public struct ClassSettingFeature {
  @Dependency(\.classUseCase) private var classUseCase

  public init() {}

  @ObservableState
  public struct State: Equatable {
    public var battle: ClassBattleSummary
    public var name = ""
    public var deadline: Date
    public var isDeadlineEnabled = true
    public var isDatePickerPresented = false
    public var requiresComment = false
    public var isLoading = false

    public init(
      battle: ClassBattleSummary,
      deadline: Date = Date().addingTimeInterval(7 * 24 * 60 * 60)
    ) {
      self.battle = battle
      self.deadline = deadline
    }

    public var deadlineText: String {
      Self.deadlineFormatter.string(from: deadline)
    }

    public var canCreate: Bool {
      !trimmedName.isEmpty && !isLoading
    }

    public var creation: ClassCreation {
      ClassCreation(
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
      return .send(.async(.create(state.creation)))
    }
  }

  private func handleAsyncAction(
    state: inout State,
    action: AsyncAction
  ) -> Effect<Action> {
    switch action {
    case let .create(creation):
      state.isLoading = true
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
      guard case let .success(room) = result else { return .none }
      return .send(.delegate(.created(room)))
    }
  }
}
