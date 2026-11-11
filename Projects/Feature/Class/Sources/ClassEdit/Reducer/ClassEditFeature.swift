//
//  ClassEditFeature.swift
//  Class
//
//  Created by Picke on 11/11/26.
//

import ClassDomainInterface
import ComposableArchitecture
import Foundation
import PickeCoreUtility

/// 운영자 클래스 수정 — Android `ClassEditScreen` 처럼 이름 변경과 마감일 연장을 한 화면에서 한다.
@Reducer
public struct ClassEditFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public var room: ClassRoom
    public var instanceID = UUID()
    public var name: String
    public var deadline: Date
    public var isNameInvalid = false
    public var deadlineValidationMessage: String?
    public var errorMessage: String?
    public var isSaving = false

    public init(room: ClassRoom) {
      self.room = room
      name = room.name
      deadline = room.deadline
    }

    public var hasDeadline: Bool {
      room.deadline != .distantFuture
    }

    public var trimmedName: String {
      name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public var isNameChanged: Bool {
      trimmedName != room.name
    }

    public var isDeadlineChanged: Bool {
      deadline != room.deadline
    }

    public var canSave: Bool {
      room.role == .owner && !isSaving && (isNameChanged || isDeadlineChanged)
    }

    public var deadlineText: String {
      hasDeadline ? deadline.formatted(.fullKoreanDateTime) : "마감일 없음"
    }
  }

  public enum Action: ViewAction, BindableAction {
    case binding(BindingAction<State>)
    case view(View)
    case inner(InnerAction)
    case delegate(DelegateAction)
  }

  @CasePathable
  public enum View: Equatable {
    case backTapped
    case deadlineFieldTapped
    case saveTapped
  }

  @CasePathable
  public enum InnerAction: Equatable {
    case saveResponse(Result<ClassRoom, ClassError>)
  }

  @CasePathable
  public enum DelegateAction: Equatable {
    case dismiss
    case editDeadline(instanceID: UUID)
    case saved(ClassRoom)
  }

  public enum CancelID: Hashable, Sendable {
    case save(UUID)
  }

  @Dependency(\.classRoomUseCase) private var classUseCase

  public var body: some Reducer<State, Action> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .binding(\.name):
        state.isNameInvalid = false
        state.errorMessage = nil
        return .none
      case .binding:
        return .none
      case let .view(viewAction):
        return handleViewAction(state: &state, action: viewAction)
      case let .inner(.saveResponse(result)):
        state.isSaving = false
        switch result {
        case let .success(room):
          state.room = room
          return .send(.delegate(.saved(room)))
        case let .failure(error):
          state.errorMessage = error.message
          return .none
        }
      case .delegate:
        return .none
      }
    }
  }
}

private extension ClassEditFeature {
  func handleViewAction(
    state: inout State,
    action: View
  ) -> Effect<Action> {
    switch action {
    case .backTapped:
      guard !state.isSaving else { return .none }
      return .send(.delegate(.dismiss))
    case .deadlineFieldTapped:
      guard !state.isSaving, state.hasDeadline else { return .none }
      return .send(.delegate(.editDeadline(instanceID: state.instanceID)))
    case .saveTapped:
      guard state.canSave else { return .none }
      state.isNameInvalid = state.trimmedName.isEmpty
      state.deadlineValidationMessage = deadlineValidationMessage(state: state)
      guard !state.isNameInvalid, state.deadlineValidationMessage == nil else { return .none }
      state.isSaving = true
      state.errorMessage = nil
      let roomID = state.room.id
      let name = state.isNameChanged ? state.trimmedName : nil
      let deadline = state.isDeadlineChanged ? state.deadline : nil
      return .run { [classUseCase] send in
        let result = await Result {
          var updated: ClassRoom?
          if let name {
            updated = try await classUseCase.updateName(id: roomID, name: name)
          }
          if let deadline {
            updated = try await classUseCase.updateDeadline(id: roomID, deadline: deadline)
          }
          guard let updated else { throw ClassError.userMessage("변경할 내용이 없어요.") }
          return updated
        }
        .mapError(ClassError.from)
        await send(.inner(.saveResponse(result)))
      }
      .cancellable(id: CancelID.save(state.instanceID), cancelInFlight: true)
    }
  }

  /// Android `ClassEditViewModel.updateClass` — 마감일은 기존보다 뒤, 이용권 종료일 이전으로만 연장한다.
  func deadlineValidationMessage(state: State) -> String? {
    guard state.isDeadlineChanged else { return nil }
    let isNotExtended = state.deadline <= state.room.deadline
    let isAfterTicketEnd = state.room.ticketExpiresAt.map { state.deadline > $0 } ?? false
    return isNotExtended || isAfterTicketEnd
      ? "기존 마감일 이후부터 이용권 종료일까지 선택할 수 있어요"
      : nil
  }
}
