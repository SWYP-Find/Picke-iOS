//
//  ClassSettingFeature.swift
//  Class
//
//  Created by Picke on 10/11/26.
//

import ClassDomainInterface
import ComposableArchitecture
import Foundation
import PickeCoreUtility
import PickeSharedUI

@Reducer
public struct ClassSettingFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public var battle: ClassBattleSummary?
    public var aiQuestion: ClassAIQuestion?
    public var topicVersionID: Int?
    public var filter: ClassTopicFilter?
    public var name = ""
    public var deadline: Date
    public var isDeadlineEnabled = true
    public var instanceID = UUID()
    public var deadlineValidationMessage: String?

    public var canEditDeadline: Bool { isDeadlineEnabled && !isLoading }
    public var requiresComment = false
    public var ownerParticipates = false
    public var isLoading = false
    public var errorMessage: String?
    @Presents public var unavailableNotice: ClassAIUnavailableNoticeFeature.State?
    @Presents public var customAlert: CustomAlertState<CustomAlertAction>?

    public init(
      battle: ClassBattleSummary,
      deadline: Date = Date().addingTimeInterval(7 * 24 * 60 * 60),
      instanceID: UUID = UUID()
    ) {
      self.battle = battle
      self.deadline = deadline
      self.instanceID = instanceID
    }

    public init(
      aiQuestion: ClassAIQuestion,
      filter: ClassTopicFilter,
      deadline: Date = Date().addingTimeInterval(7 * 24 * 60 * 60),
      instanceID: UUID = UUID()
    ) {
      self.aiQuestion = aiQuestion
      self.filter = filter
      self.deadline = deadline
      self.instanceID = instanceID
    }

    public init(
      topicVersion: ClassTopicVersion,
      filter: ClassTopicFilter,
      deadline: Date = Date().addingTimeInterval(7 * 24 * 60 * 60),
      instanceID: UUID = UUID()
    ) {
      self.aiQuestion = ClassAIQuestion(version: topicVersion)
      self.topicVersionID = topicVersion.id
      self.filter = filter
      self.deadline = deadline
      self.instanceID = instanceID
    }

    public var deadlineText: String {
      deadline.formatted(.fullKoreanDateTime)
    }

    public var heading: String {
      "거의 다 왔어요!\n클래스 정보를 입력해 주세요"
    }

    public var deadlineDescription: String {
      "마감 전까지 학생이 클래스에 참여할 수 있어요"
    }

    public var commentDescription: String {
      "멤버의 생각을 댓글로 확인해요."
    }

    public var ownerParticipationTitle: String {
      "나도 참여하기"
    }

    public var ownerParticipationDescription: String {
      aiQuestion == nil ? "운영자도 배틀에 참여해요" : "운영자도 콘텐츠에 참여해요."
    }

    public var canCreate: Bool {
      !trimmedName.isEmpty && !isLoading
    }

    public var creation: ClassCreation? {
      if let battle {
        return ClassCreation(
          name: trimmedName,
          deadline: isDeadlineEnabled ? deadline : .distantFuture,
          battleId: battle.id,
          allowsAnonymousOpinion: false,
          requiresComment: requiresComment,
          ownerParticipates: ownerParticipates
        )
      }
      guard let topicVersionID, aiQuestion != nil else { return nil }
      return ClassCreation(
        name: trimmedName,
        deadline: isDeadlineEnabled ? deadline : .distantFuture,
        topicVersionId: topicVersionID,
        allowsAnonymousOpinion: false,
        requiresComment: requiresComment,
        ownerParticipates: ownerParticipates
      )
    }

    public var aiBattle: ClassBattleSummary? {
      guard let aiQuestion, let filter, aiQuestion.id > 0 else { return nil }
      return ClassBattleSummary(
        id: -aiQuestion.id,
        title: aiQuestion.title,
        summary: aiQuestion.summary,
        philosopherA: aiQuestion.philosopherAName ?? "A 입장",
        optionATitle: aiQuestion.optionATitle,
        optionADescription: aiQuestion.optionADescription,
        philosopherB: aiQuestion.philosopherBName ?? "B 입장",
        optionBTitle: aiQuestion.optionBTitle,
        optionBDescription: aiQuestion.optionBDescription,
        category: ClassCategory.allCases.first(where: { $0.title == aiQuestion.category })
          ?? filter.category ?? .philosophy,
        categoryDisplayTitle: aiQuestion.category,
        level: filter.level,
        audioDuration: 0,
        viewCount: 0
      )
    }

    public var aiCreation: ClassCreation? {
      guard let topicVersionID else { return nil }
      return ClassCreation(
        name: trimmedName,
        deadline: isDeadlineEnabled ? deadline : .distantFuture,
        topicVersionId: topicVersionID,
        allowsAnonymousOpinion: false,
        requiresComment: requiresComment,
        ownerParticipates: ownerParticipates
      )
    }

    private var trimmedName: String {
      name.trimmingCharacters(in: .whitespacesAndNewlines)
    }
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
    case editDeadline(instanceID: UUID)
  }

  nonisolated enum CancelID: Hashable {
    case create
  }

  @Dependency(\.date) private var date
  @Dependency(\.classUseCase) private var classUseCase

  public var body: some Reducer<State, Action> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .binding(\.deadline), .binding(\.isDeadlineEnabled):
        state.deadlineValidationMessage = nil
        return .none

      case .binding:
        return .none

      case let .unavailableNotice(noticeAction):
        return handleUnavailableNoticeAction(state: &state, action: noticeAction)

      case let .customAlert(alertAction):
        return handleCustomAlertAction(state: &state, action: alertAction)

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

// MARK: - Action Handlers

extension ClassSettingFeature {
  private func handleUnavailableNoticeAction(
    state: inout State,
    action: PresentationAction<ClassAIUnavailableNoticeFeature.Action>
  ) -> Effect<Action> {
    switch action {
    case .presented(.dismissTapped):
      state.unavailableNotice = nil
      return .none
    case .dismiss:
      return .none
    }
  }

  private func handleCustomAlertAction(
    state: inout State,
    action: PresentationAction<CustomAlertAction>
  ) -> Effect<Action> {
    switch action {
    case .presented(.confirmTapped), .presented(.cancelTapped), .dismiss:
      state.customAlert = nil
      state.errorMessage = nil
      return .none
    case .presented:
      return .none
    }
  }

  private func handleViewAction(
    state: inout State,
    action: View
  ) -> Effect<Action> {
    switch action {
    case .backTapped:
      return .send(.delegate(.dismiss))

    case .deadlineFieldTapped:
      guard state.canEditDeadline else { return .none }
      return .send(.delegate(.editDeadline(instanceID: state.instanceID)))

    case .createTapped:
      guard state.canCreate else { return .none }
      guard !state.isDeadlineEnabled || state.deadline >= date.now else {
        state.deadlineValidationMessage = "현재 이후 시간을 선택해 주세요."
        return .none
      }
      if state.aiQuestion != nil, state.topicVersionID == nil {
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
