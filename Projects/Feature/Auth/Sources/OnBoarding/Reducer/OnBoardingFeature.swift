//
//  OnBoardingFeature.swift
//  Auth
//
//  Created by Wonji Suh  on 5/15/26.
//

import ComposableArchitecture
import AuthInterface
import PickeDesignKit
import Foundation

@Reducer
public struct OnBoardingFeature {
  public init() {}

  public struct Page: Equatable, Identifiable {
    public let id: Int
    public let title: String
    public let subtitle: String
    public let imageAsset: ImageAsset

    public init(
      id: Int,
      title: String,
      subtitle: String,
      imageAsset: ImageAsset
    ) {
      self.id = id
      self.title = title
      self.subtitle = subtitle
      self.imageAsset = imageAsset
    }
  }

  public static let pages: [Page] = [
    .init(
      id: 0,
      title: "AI 철학자들의 실시간 배틀",
      subtitle: "위대한 사상가들의 토론을 듣고,\n당신의 입장을 선택하세요.",
      imageAsset: .onboarding1
    ),
    .init(
      id: 1,
      title: "배틀 승리로 주어지는 포인트",
      subtitle: "배틀 참여로 포인트를 모아\n나만의 배틀을 제안해보세요.",
      imageAsset: .onboarding2
    ),
    .init(
      id: 2,
      title: "매일 새로운 투표, 당신의 Pick은?",
      subtitle: "철학, 예술, 과학, 사회 등\n다양한 주제의 배틀과 투표가 기다리고 있어요.",
      imageAsset: .onboarding3
    ),
    .init(
      id: 3,
      title: "나와 가장 닮은 철학자는?",
      subtitle: "토론 성향에 따라 철학자 유형이 부여돼요.\n배틀에 참여해 새로운 나를 발견해보세요!",
      imageAsset: .onboarding4
    ),
  ]

  public static var pageCount: Int { pages.count }

  @ObservableState
  public struct State: Equatable {
    public var currentIndex: Int

    public init(currentIndex: Int = 0) {
      self.currentIndex = currentIndex
    }

    public var isLastPage: Bool {
      currentIndex >= OnBoardingFeature.pageCount - 1
    }

    public var currentPage: Page {
      OnBoardingFeature.pages[currentIndex]
    }

    /// 하단 CTA 라벨. 마지막 페이지는 "시작하기", 그 외는 "다음".
    public var primaryButtonTitle: String {
      isLastPage ? "시작하기" : "다음"
    }
  }

  public enum Action: ViewAction, BindableAction {
    case binding(BindingAction<State>)
    case view(View)
    case async(AsyncAction)
    case inner(InnerAction)
    case delegate(OnBoardingDelegate)
  }

  // MARK: - ViewAction

  @CasePathable
  public enum View {
    case primaryButtonTapped
    case indicatorTapped(index: Int)
  }

  // MARK: - AsyncAction

  public enum AsyncAction: Equatable {}

  // MARK: - InnerAction

  public enum InnerAction: Equatable {}

  // MARK: - DelegateAction

  nonisolated enum CancelID: Hashable {}

  public var body: some Reducer<State, Action> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .binding:
        .none

      case let .view(viewAction):
        handleViewAction(state: &state, action: viewAction)

      case let .async(asyncAction):
        handleAsyncAction(state: &state, action: asyncAction)

      case let .inner(innerAction):
        handleInnerAction(state: &state, action: innerAction)

      case let .delegate(delegateAction):
        handleDelegateAction(state: &state, action: delegateAction)
      }
    }
  }
}

extension OnBoardingFeature {
  private func handleViewAction(
    state: inout State,
    action: View
  ) -> Effect<Action> {
    switch action {
    case .primaryButtonTapped:
      if state.isLastPage {
        return .send(.delegate(.presentMainTab))
      }
      state.currentIndex = min(state.currentIndex + 1, OnBoardingFeature.pageCount - 1)
      return .none

    case let .indicatorTapped(index):
      state.currentIndex = max(0, min(index, OnBoardingFeature.pageCount - 1))
      return .none
    }
  }

  private func handleAsyncAction(
    state _: inout State,
    action: AsyncAction
  ) -> Effect<Action> {
    switch action {}
  }

  private func handleInnerAction(
    state _: inout State,
    action: InnerAction
  ) -> Effect<Action> {
    switch action {}
  }

  private func handleDelegateAction(
    state _: inout State,
    action: OnBoardingDelegate
  ) -> Effect<Action> {
    switch action {
    case .presentMainTab:
      .none
    }
  }
}
