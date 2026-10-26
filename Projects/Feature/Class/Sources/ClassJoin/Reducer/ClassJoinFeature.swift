//
//  ClassJoinFeature.swift
//  Class
//
//  Created by Picke on 10/11/26.
//

import ClassDomainInterface
import ComposableArchitecture
import Foundation

@Reducer
public struct ClassJoinFeature {
  public init() {}

  public enum Mode: Equatable {
    case code
    case nickname
    case ownerName
  }

  @ObservableState
  public struct State: Equatable {
    public static let nicknameLimit = 12

    public var mode: Mode
    public var joinCode = ""
    public var nickname = ""
    public var preview: ClassRoom?
    public var joinPreview: ClassJoinPreview? = nil
    public let instanceID: UUID?
    public var activeFindRequestID: UUID?
    public var activeJoinRequestID: UUID?
    public var activeOwnerRequestID: UUID?
    public var isLoading = false
    public var errorMessage: String?
    public var nicknameErrorMessage: String?

    public init(
      mode: Mode = .code,
      preview: ClassRoom? = nil,
      instanceID: UUID? = nil
    ) {
      self.mode = mode
      self.preview = preview
      self.instanceID = instanceID
    }

    public init(
      mode: Mode,
      preview: ClassJoinPreview,
      instanceID: UUID?
    ) {
      self.mode = mode
      joinPreview = preview
      self.instanceID = instanceID
    }

    public var canFindClass: Bool {
      mode == .code && joinCode.count == 6 && !isLoading
    }

    public var codeCharacters: [String] {
      let characters = Array(joinCode.prefix(6)).map(String.init)
      return characters + Array(repeating: "-", count: max(0, 6 - characters.count))
    }

    public var primaryButtonTitle: String {
      switch mode {
      case .code, .nickname: return "클래스 참여하기"
      case .ownerName: return "입장하기"
      }
    }

    public var navigationCenterTitle: String? {
      switch mode {
      case .code, .nickname: return "클래스 참여"
      case .ownerName: return "이름 입력"
      }
    }

    public var navigationLeadingTitle: String? {
      nil
    }

    public var nicknamePlaceholder: String {
      switch mode {
      case .nickname: return "내용을 입력하세요"
      case .code, .ownerName: return "이름을 입력해주세요"
      }
    }

    public var nicknameCharacterCount: Int {
      nickname.trimmingCharacters(in: .whitespacesAndNewlines).count
    }

    public var nicknameValidationMessage: String? {
      if nicknameCharacterCount > Self.nicknameLimit {
        return "이름은 12자 이내로 입력해 주세요."
      }
      return nicknameErrorMessage
    }

    public var canJoin: Bool {
      (mode == .nickname || mode == .ownerName)
        && (mode == .nickname ? joinPreview != nil : preview != nil)
        && (1 ... Self.nicknameLimit).contains(nicknameCharacterCount)
        && !isLoading
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
  public enum View {
    case backTapped
    case findTapped
    case joinTapped
    case createClassTapped
  }

  @CasePathable
  public enum AsyncAction: Equatable {
    case find(String)
    case join(joinCode: String, nickname: String)
    case nameOwner(roomID: Int, nickname: String, instanceID: UUID, requestID: UUID)
  }

  @CasePathable
  public enum InnerAction: Equatable {
    case found(Result<ClassJoinPreview, ClassError>, instanceID: UUID?, requestID: UUID)
    case joined(Result<ClassRoom, ClassError>, nickname: String, instanceID: UUID?, requestID: UUID)
    case ownerNamed(Result<ClassRoom, ClassError>, instanceID: UUID, requestID: UUID)
  }

  @CasePathable
  public enum DelegateAction: Equatable {
    case dismiss
    case createClassRequested
    case found(ClassJoinPreview, instanceID: UUID?)
    case joined(ClassRoom, nickname: String, instanceID: UUID?)
    case ownerNamed(ClassRoom, instanceID: UUID)
  }

  public nonisolated enum CancelID: Hashable, Sendable {
    case find(UUID?)
    case join(UUID?)
    case nameOwner(UUID)
  }

  @Dependency(\.classUseCase) private var classUseCase
  @Dependency(\.classMemberUseCase) private var classMemberUseCase
  @Dependency(\.uuid) private var uuid

  public var body: some Reducer<State, Action> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .binding:
        state.joinCode = String(
          state.joinCode.uppercased()
            .filter { $0.isASCII && ($0.isLetter || $0.isNumber) }
            .prefix(6)
        )
        state.errorMessage = nil
        state.nicknameErrorMessage = nil
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

// MARK: - Action Handlers

extension ClassJoinFeature {
  private func handleViewAction(
    state: inout State,
    action: View
  ) -> Effect<Action> {
    switch action {
    case .backTapped:
      state.activeFindRequestID = nil
      state.activeJoinRequestID = nil
      state.activeOwnerRequestID = nil
      state.isLoading = false
      var effects: [Effect<Action>] = [
        .cancel(id: CancelID.find(state.instanceID)),
        .cancel(id: CancelID.join(state.instanceID)),
        .send(.delegate(.dismiss)),
      ]
      if let instanceID = state.instanceID {
        effects.append(.cancel(id: CancelID.nameOwner(instanceID)))
      }
      return .merge(effects)

    case .findTapped:
      guard state.canFindClass else { return .none }
      return .send(.async(.find(state.joinCode)))

    case .createClassTapped:
      guard state.mode == .code, !state.isLoading else { return .none }
      return .send(.delegate(.createClassRequested))

    case .joinTapped:
      guard state.canJoin else { return .none }
      let nickname = state.nickname.trimmingCharacters(in: .whitespacesAndNewlines)
      switch state.mode {
      case .nickname:
        guard let preview = state.joinPreview else { return .none }
        return .send(.async(.join(joinCode: preview.inviteCode, nickname: nickname)))
      case .ownerName:
        guard let room = state.preview, let instanceID = state.instanceID else { return .none }
        return .send(.async(.nameOwner(
          roomID: room.id,
          nickname: nickname,
          instanceID: instanceID,
          requestID: uuid()
        )))
      case .code:
        return .none
      }
    }
  }

  private func handleAsyncAction(
    state: inout State,
    action: AsyncAction
  ) -> Effect<Action> {
    switch action {
    case let .find(code):
      state.isLoading = true
      let requestID = uuid()
      state.activeFindRequestID = requestID
      state.errorMessage = nil
      state.nicknameErrorMessage = nil
      return .run { [classUseCase, instanceID = state.instanceID] send in
        let result = await Result {
          try await classUseCase.fetchClassPreview(joinCode: code)
        }
        .mapError(ClassError.from)
        guard !Task.isCancelled else { return }
        await send(.inner(.found(result, instanceID: instanceID, requestID: requestID)))
      }
      .cancellable(id: CancelID.find(state.instanceID), cancelInFlight: true)

    case let .join(code, nickname):
      state.isLoading = true
      let requestID = uuid()
      state.activeJoinRequestID = requestID
      state.errorMessage = nil
      state.nicknameErrorMessage = nil
      return .run { [classUseCase, instanceID = state.instanceID] send in
        let result = await Result {
          try await classUseCase.joinClass(joinCode: code, nickname: nickname)
        }
        .mapError(ClassError.from)
        guard !Task.isCancelled else { return }
        await send(.inner(.joined(
          result,
          nickname: nickname,
          instanceID: instanceID,
          requestID: requestID
        )))
      }
      .cancellable(id: CancelID.join(state.instanceID), cancelInFlight: true)

    case let .nameOwner(roomID, nickname, instanceID, requestID):
      guard state.instanceID == instanceID, state.preview?.id == roomID else { return .none }
      state.isLoading = true
      state.activeOwnerRequestID = requestID
      state.errorMessage = nil
      state.nicknameErrorMessage = nil
      return .run { [classMemberUseCase, room = state.preview] send in
        let result = await Result { () async throws -> ClassRoom in
          _ = try await classMemberUseCase.updateMyDisplayName(classID: roomID, name: nickname)
          guard let room else { throw ClassError.invalidCode }
          return room
        }
        .mapError(ClassError.from)
        await send(.inner(.ownerNamed(result, instanceID: instanceID, requestID: requestID)))
      }
      .cancellable(id: CancelID.nameOwner(instanceID), cancelInFlight: true)
    }
  }

  private func handleInnerAction(
    state: inout State,
    action: InnerAction
  ) -> Effect<Action> {
    switch action {
    case let .found(.success(room), instanceID, requestID):
      guard state.instanceID == instanceID, state.activeFindRequestID == requestID else { return .none }
      state.isLoading = false
      state.activeFindRequestID = nil
      return .send(.delegate(.found(room, instanceID: instanceID)))

    case let .joined(.success(room), nickname, instanceID, requestID):
      guard state.instanceID == instanceID, state.activeJoinRequestID == requestID else { return .none }
      state.isLoading = false
      state.activeJoinRequestID = nil
      state.preview = nil
      state.joinPreview = nil
      return .send(.delegate(.joined(room, nickname: nickname, instanceID: instanceID)))

    case let .ownerNamed(.success(room), instanceID, requestID):
      guard state.instanceID == instanceID, state.activeOwnerRequestID == requestID else { return .none }
      state.isLoading = false
      state.activeOwnerRequestID = nil
      state.preview = nil
      return .send(.delegate(.ownerNamed(room, instanceID: instanceID)))

    case let .joined(.failure(.duplicateName), _, instanceID, requestID):
      guard state.instanceID == instanceID, state.activeJoinRequestID == requestID else { return .none }
      state.isLoading = false
      state.activeJoinRequestID = nil
      state.nicknameErrorMessage = ClassError.duplicateName.message
      return .none

    case let .ownerNamed(.failure(error), instanceID, requestID):
      guard state.instanceID == instanceID, state.activeOwnerRequestID == requestID else { return .none }
      state.isLoading = false
      state.activeOwnerRequestID = nil
      if error == .duplicateName {
        state.nicknameErrorMessage = error.message
      } else {
        state.errorMessage = error.message
      }
      return .none

    case let .found(.failure(error), instanceID, requestID):
      guard state.instanceID == instanceID, state.activeFindRequestID == requestID else { return .none }
      state.activeFindRequestID = nil
      state.isLoading = false
      state.errorMessage = error.message
      return .none

    case let .joined(.failure(error), _, instanceID, requestID):
      guard state.instanceID == instanceID, state.activeJoinRequestID == requestID else { return .none }
      state.activeJoinRequestID = nil
      state.isLoading = false
      state.errorMessage = error.message
      return .none
    }
  }
}
