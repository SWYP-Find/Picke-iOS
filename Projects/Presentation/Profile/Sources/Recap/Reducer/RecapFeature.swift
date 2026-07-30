//
//  RecapFeature.swift
//  Profile
//

import Foundation
import ProfileDomainInterface
import UIKit

import ComposableArchitecture
import LogMacro
import AnalyticsServiceInterface
import CommonDomainInterface

@Reducer
public struct RecapFeature {
  public init() {}

  /// 소비한 배틀이 이 수 미만이면 잠금. (서버 미제공 — 클라이언트 상수)
  static let unlockThreshold = 5

  @ObservableState
  public struct State: Equatable {
    public var isLoading: Bool = false
    public var recap: PhilosopherRecap?
    /// 애플 시스템 공유 시트 트리거.
    public var shareItem: ShareItem?

    public init() {}

    /// 소비한 배틀(총 참여) < 5 → 잠금.
    public var isLocked: Bool {
      guard let recap else { return false }
      return recap.preferenceReport.totalParticipation < RecapFeature.unlockThreshold
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
    case onAppear
    case backTapped
    /// 공유하기 — 철학자 유형 카드를 이미지로 렌더한 스냅샷(View 에서 ImageRenderer 로 캡처)을 함께 전달.
    case shareTapped(snapshot: Data?)
  }

  public enum AsyncAction: Equatable {
    case fetch
  }

  public enum InnerAction: Equatable {
    case recapResponse(Result<PhilosopherRecap, ProfileError>)
  }

  public enum DelegateAction: Equatable {
    case dismiss
    case share(PhilosopherRecap)
  }

  nonisolated enum CancelID: Hashable {
    case fetch
  }

  @Dependency(\.profileUseCase) private var profileUseCase
  @Dependency(\.analyticsUseCase) private var analyticsUseCase

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

      case let .delegate(delegateAction):
        return handleDelegateAction(state: &state, action: delegateAction)
      }
    }
  }
}

extension RecapFeature {
  private func handleViewAction(
    state: inout State,
    action: View
  ) -> Effect<Action> {
    switch action {
    case .onAppear:
      analyticsUseCase.track(.screenView(screen: .recap, referrer: nil))
      guard state.recap == nil else { return .none }
      return .send(.async(.fetch))

    case .backTapped:
      return .send(.delegate(.dismiss))

    case let .shareTapped(snapshot):
      guard let recap = state.recap else { return .none }
      let text = [
        "나의 철학자 유형: \(recap.myCard.typeName)",
        recap.myCard.description,
        recap.myCard.keywordTags.map { "#\($0)" }.joined(separator: " "),
      ]
      .filter { !$0.isEmpty }
      .joined(separator: "\n\n")
      var items: [Any] = [text]
      // 인스타 스토리/게시물 공유를 위해 카드 스냅샷 이미지를 우선 포함.
      if let snapshot, let image = UIImage(data: snapshot) {
        items.append(image)
      } else if !recap.myCard.imageURL.isEmpty, let url = URL(string: recap.myCard.imageURL) {
        items.append(url)
      }
      state.shareItem = ShareItem(items: items)
      // 모든 공유는 share_action 으로 통일 (report_action 은 조회 전용).
      analyticsUseCase.track(.shareAction(ShareActionData(target: .recap)))
      return .none
    }
  }

  private func handleAsyncAction(
    state: inout State,
    action: AsyncAction
  ) -> Effect<Action> {
    switch action {
    case .fetch:
      state.isLoading = true
      return .run { [useCase = profileUseCase] send in
        let result = await Result {
          try await useCase.fetchRecap()
        }
        .mapError(ProfileError.from)
        return await send(.inner(.recapResponse(result)))
      }
      .cancellable(id: CancelID.fetch, cancelInFlight: true)
    }
  }

  private func handleInnerAction(
    state: inout State,
    action: InnerAction
  ) -> Effect<Action> {
    switch action {
    case let .recapResponse(result):
      state.isLoading = false
      switch result {
      case let .success(recap):
        state.recap = recap
        analyticsUseCase.track(
          .reportAction(ReportActionData(actionType: .view, topIndicator: recap.myCard.typeName))
        )
      case let .failure(error):
        Log.error("[RecapFeature] fetchRecap failed: \(error.localizedDescription)")
      }
      return .none
    }
  }

  private func handleDelegateAction(
    state _: inout State,
    action: DelegateAction
  ) -> Effect<Action> {
    switch action {
    case .dismiss:
      return .none
    case .share:
      return .none
    }
  }
}
