//
//  ClassShareFeature.swift
//  Class
//
//  Created by Picke on 10/11/26.
//

import ClassDomainInterface
import ComposableArchitecture
import Foundation
import PickeCoreUtility

@Reducer
public struct ClassShareFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public enum ViewState: Equatable {
      case loading
      case loaded
      case error
    }

    public var room: ClassRoom
    /// 클래스 상세·목록의 "참여 코드 공유"로 연 경우. 만들기 직후 공유와 이동 경로가 다르다.
    public var isExistingClass: Bool
    public var viewState: ViewState = .loading
    public var toastMessage: String?

    public init(room: ClassRoom, isExistingClass: Bool = false) {
      self.room = room
      self.isExistingClass = isExistingClass
    }

    /// 마감일을 끈 클래스는 `.distantFuture` 로 만들어지므로 표시하지 않는다.
    public var deadlineText: String? {
      guard room.deadline != .distantFuture else { return nil }
      return "참여 마감・\(room.deadline.formatted(.fullKoreanDateTime))"
    }

    /// Android `class_share_code_message`.
    public var shareMessage: String {
      "[픽케] '\(room.name)' 클래스에 초대합니다.\n참여 코드: \(room.joinCode)\n픽케 앱 클래스 탭에서 참여 코드를 입력해 주세요."
    }
  }

  public enum Action: ViewAction {
    case view(View)
    case inner(InnerAction)
    case delegate(DelegateAction)
  }

  @CasePathable
  public enum View {
    case onAppear
    case closeTapped
    case enterClassTapped
    case toastShown
  }

  public enum InnerAction: Equatable {
    case loaded(ClassRoom)
    case loadFailed
  }

  @CasePathable
  public enum DelegateAction: Equatable {
    case dismiss
    case nameOwner(ClassRoom)
    case enterClass(ClassRoom)
    case openMyClasses
  }

  @Dependency(\.classUseCase) private var classUseCase

  public var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case let .view(viewAction):
        return handleViewAction(state: &state, action: viewAction)

      case let .inner(innerAction):
        return handleInnerAction(state: &state, action: innerAction)

      case .delegate:
        return .none
      }
    }
  }
}

// MARK: - Action Handlers

extension ClassShareFeature {
  private func handleViewAction(
    state: inout State,
    action: View
  ) -> Effect<Action> {
    switch action {
    case .onAppear:
      guard state.viewState == .loading else { return .none }
      // Android ClassShareViewModel.fetchClassShare: 상세와 배틀을 함께 받아 선택한 배틀 카드를 채운다.
      let classID = state.room.id
      return .run { [classUseCase] send in
        do {
          async let detailRoom = classUseCase.fetchClass(id: classID)
          async let session = classUseCase.fetchBattle(classID: classID)
          let room = try await detailRoom.applyingBattle(session.battle)
          await send(.inner(.loaded(room)))
        } catch {
          await send(.inner(.loadFailed))
        }
      }

    case .closeTapped:
      return .send(.delegate(.dismiss))

    case .enterClassTapped:
      if state.isExistingClass {
        return .send(.delegate(.openMyClasses))
      }
      return state.room.ownerParticipates
        ? .send(.delegate(.nameOwner(state.room)))
        : .send(.delegate(.enterClass(state.room)))

    case .toastShown:
      state.toastMessage = nil
      return .none
    }
  }

  private func handleInnerAction(
    state: inout State,
    action: InnerAction
  ) -> Effect<Action> {
    switch action {
    case let .loaded(room):
      state.room = room
      state.viewState = .loaded
      return .none

    case .loadFailed:
      state.viewState = .error
      state.toastMessage = "정보를 불러오지 못했어요"
      return .none
    }
  }
}
