//
//  ClassDeadlineEditFeature.swift
//  Class
//
//  Created by Picke on 10/12/26.
//

import ClassDomainInterface
import ComposableArchitecture
import Foundation
import PickeCoreUtility

@Reducer
public struct ClassDeadlineEditFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public let room: ClassRoom
    public let instanceID: UUID
    public let referenceNow: Date
    public var draftDeadline: Date
    public var isDeadlineEnabled: Bool
    public var isSaving = false
    public var activeRequestID: UUID?
    public var errorMessage: String?

    public init(
      room: ClassRoom,
      instanceID: UUID,
      referenceNow: Date
    ) {
      self.room = room
      self.instanceID = instanceID
      self.referenceNow = referenceNow
      isDeadlineEnabled = room.deadline != .distantFuture
      draftDeadline = room.deadline == .distantFuture
        ? AppDateFormat.calendar.date(byAdding: .day, value: 7, to: referenceNow) ?? referenceNow
        .addingTimeInterval(604_800)
        : room.deadline
    }

    public var minimumSelectableDate: Date {
      max(room.deadline, referenceNow)
    }

    public var validationMessage: String? {
      guard isDeadlineEnabled else { return nil }
      if draftDeadline <= room.deadline { return "마감일은 기존 마감일보다 뒤로 연장만 할 수 있습니다." }
      if draftDeadline < referenceNow { return "현재 이후 시간을 선택해 주세요." }
      if let ticketExpiresAt = room.ticketExpiresAt, draftDeadline > ticketExpiresAt {
        return "마감일은 이용권 종료일 이전이어야 합니다."
      }
      return nil
    }

    public var selectedDeadlineText: String {
      isDeadlineEnabled ? draftDeadline.formatted(.fullKoreanDateTime) : "마감일 없음"
    }

    public var canSave: Bool {
      room.role == .owner && room.deadline != .distantFuture && !isSaving
        && isDeadlineEnabled && validationMessage == nil && draftDeadline != room.deadline
    }
  }

  public enum Action: ViewAction, BindableAction {
    case binding(BindingAction<State>)
    case view(View)
    case async(AsyncAction)
    case inner(InnerAction)
    case delegate(DelegateAction)
  }

  @CasePathable
  public enum View: Equatable {
    case backTapped
    case deadlineEnabledChanged(Bool)
    case saveTapped
  }

  @CasePathable
  public enum AsyncAction: Equatable {
    case save(roomID: Int, deadline: Date, instanceID: UUID, requestID: UUID)
  }

  @CasePathable
  public enum InnerAction: Equatable {
    case saveResponse(
      Result<ClassRoom, ClassError>,
      roomID: Int,
      instanceID: UUID,
      requestID: UUID
    )
  }

  @CasePathable
  public enum DelegateAction: Equatable {
    case dismiss
    case saved(ClassRoom, instanceID: UUID, requestID: UUID)
  }

  public enum CancelID: Hashable, Sendable {
    case save(UUID)
  }

  @Dependency(\.classUseCase) private var classUseCase
  @Dependency(\.date) private var date
  @Dependency(\.uuid) private var uuid

  public var body: some Reducer<State, Action> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .binding:
        state.errorMessage = nil
        return .none
      case .view(.backTapped):
        guard !state.isSaving else { return .none }
        state.activeRequestID = nil
        return .merge(
          .cancel(id: CancelID.save(state.instanceID)),
          .send(.delegate(.dismiss))
        )
      case let .view(.deadlineEnabledChanged(enabled)):
        guard !state.isSaving, enabled, state.room.deadline != .distantFuture else { return .none }
        state.isDeadlineEnabled = enabled
        state.errorMessage = nil
        return .none
      case .view(.saveTapped):
        guard state.canSave else { return .none }
        guard state.draftDeadline >= date.now else {
          state.errorMessage = "현재 이후 시간을 선택해 주세요."
          return .none
        }
        let requestID = uuid()
        state.activeRequestID = requestID
        state.isSaving = true
        state.errorMessage = nil
        return .send(.async(.save(
          roomID: state.room.id,
          deadline: state.draftDeadline,
          instanceID: state.instanceID,
          requestID: requestID
        )))
      case let .async(.save(roomID, deadline, instanceID, requestID)):
        guard state.instanceID == instanceID,
              state.room.id == roomID,
              state.activeRequestID == requestID,
              state.isSaving else { return .none }
        return .run { [classUseCase] send in
          let result = await Result {
            try await classUseCase.updateDeadline(id: roomID, deadline: deadline)
          }
          .mapError(ClassError.from)
          guard !Task.isCancelled else { return }
          await send(.inner(.saveResponse(
            result,
            roomID: roomID,
            instanceID: instanceID,
            requestID: requestID
          )))
        }
        .cancellable(id: CancelID.save(instanceID), cancelInFlight: true)
      case let .inner(.saveResponse(result, roomID, instanceID, requestID)):
        guard state.instanceID == instanceID,
              state.room.id == roomID,
              state.activeRequestID == requestID,
              state.isSaving else { return .none }
        switch result {
        case let .success(room):
          guard room.id == roomID else {
            state.isSaving = false
            state.activeRequestID = nil
            state.errorMessage = "마감일 변경 결과를 확인하지 못했어요."
            return .none
          }
          return .send(.delegate(.saved(room, instanceID: instanceID, requestID: requestID)))
        case let .failure(error):
          state.isSaving = false
          state.activeRequestID = nil
          state.errorMessage = error.message
          return .none
        }
      case .delegate:
        return .none
      }
    }
  }
}
