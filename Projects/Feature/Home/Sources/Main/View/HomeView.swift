//
//  HomeView.swift
//  Home
//
//  Created by Picke on 5/15/26.
//

import ComposableArchitecture
import FeatureSharedUI
import HomeDomainInterface
import PickeDesignKit
import PickeSharedUI
import SwiftUI

@ViewAction(for: HomeFeature.self)
public struct HomeView: View {
  @Bindable public var store: StoreOf<HomeFeature>
  @Environment(\.scenePhase) private var scenePhase

  private static let topAnchorID = "homeTop"

  public init(store: StoreOf<HomeFeature>) {
    self.store = store
  }

  public var body: some View {
    VStack(spacing: 0) {
      HomeHeaderView(
        hasUnread: store.hasUnreadNotification,
        isLoading: store.shouldShowBellSkeleton,
        onNotificationTapped: { send(.notificationTapped) }
      ) // sticky — 스크롤 영향 없음

      scrollContent
    }
    .screenBackground()
    .pickeModal(
      $store.scope(
        state: \.attendanceModal,
        action: \.attendanceModal
      )
    ) { modalStore in
      AttendanceModalView(store: modalStore)
    }
    .onAppear { send(.onAppear) }
    .onChange(of: scenePhase) { oldPhase, newPhase in
      // Android `AppLifecycleObserver.onStart` — 앱으로 돌아올 때마다 하루 1회 출석 체크.
      guard oldPhase != .active, newPhase == .active else { return }
      send(.appBecameActive)
    }
    .onChange(of: store.toastMessage, initial: true) { _, message in
      guard let message else { return }
      ToastManager.shared.showError(message)
      send(.toastShown)
    }
    .navigationBarHidden(true)
    .scrollIndicators(.hidden)
    // 세로는 항상 튕겨야 내용이 짧은 빈 화면에서도 당겨서 새로고침이 된다.
    .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
  }
}

// MARK: - Sections

extension HomeView {
  /// 홈 탭 재선택 시 맨 위 앵커로 스크롤하고, 당기면 새로고침한다(Android PullToRefreshBox).
  private var scrollContent: some View {
    ScrollViewReader { proxy in
      ScrollView(showsIndicators: false) {
        VStack(spacing: 0) {
          Color.clear
            .frame(height: 0)
            .id(Self.topAnchorID)
          contentSection()
        }
      }
      .refreshable {
        await send(.pullToRefresh).finish()
      }
      .onChange(of: store.scrollToTopRequest) {
        withAnimation {
          proxy.scrollTo(Self.topAnchorID, anchor: .top)
        }
      }
    }
  }

  @ViewBuilder
  private func contentSection() -> some View {
    if store.shouldShowSkeleton {
      HomeSkeletonView()
    } else if !store.hasVisibleHomeContent {
      emptyHomeSection()
    } else {
      loadedSection()
    }
  }

  /// 섹션 간격은 Android `HomeScreen` 의 Spacer 값(24/40/24/32/32/40)을 그대로 따른다.
  @ViewBuilder
  private func loadedSection() -> some View {
    VStack(spacing: 0) {
      if !store.heroes.isEmpty {
        HeroCarouselView(
          heroes: store.heroes,
          currentIndex: $store.heroIndex,
          onTap: { send(.heroTapped($0)) }
        )
        .padding(.bottom, 24)
      }

      hotBattlesSection()
        .padding(.bottom, 40)
      adSection()
        .padding(.bottom, 24)
      if !store.bestBattles.isEmpty {
        bestBattlesSection()
          .padding(.bottom, 32)
      }
      if !store.bestComments.isEmpty {
        bestCommentsSection()
          .padding(.bottom, 32)
      }
      if !store.newBattles.isEmpty {
        newBattlesSection()
      }
    }
    .padding(.bottom, 40)
  }

  /// Android 빈 상태 — 로고(borderBeigeDefault 색) + 문구를 스크롤 영역 가운데에 둔다.
  @ViewBuilder
  private func emptyHomeSection() -> some View {
    VStack(spacing: 16) {
      Image(asset: .appLogo)
        .renderingMode(.template)
        .resizable()
        .scaledToFit()
        .frame(width: 160, height: 120)
        .foregroundStyle(.borderBeigeDefault)
        .accessibilityLabel("빈 화면 로고")
      Text("아직 준비된 배틀이 없어요!")
        .pretendardFont(.bodyMedium)
        .foregroundStyle(.beige800)
    }
    .frame(maxWidth: .infinity)
    .containerRelativeFrame(.vertical)
  }

  /// 배틀 섹션 아래 네이티브 광고 — AdFit 은 한 화면에 같은 단위 1개만 허용해 호출부에서 하나만 그린다.
  @ViewBuilder
  private func adSection() -> some View {
    AdFitNativeAdView(
      unit: .wide,
      onAdClick: { send(.adNativeClicked) }
    )
    .frame(maxWidth: .infinity)
  }

  @ViewBuilder
  private func hotBattlesSection() -> some View {
    VStack(alignment: .leading, spacing: 0) {
      HomeSectionHeader(title: "지금 뜨는 배틀")
      if store.hotBattles.isEmpty {
        Text("지금 뜨는 배틀이 아직 없어요")
          .pretendardFont(.bodyMedium)
          .foregroundStyle(.textMuted)
          .multilineTextAlignment(.center)
          .frame(width: 220, height: 274)
          .background(.surfaceBeigeSubtle)
          .roundedBorder(
            .borderBeigeDefault,
            lineWidth: 1,
            insideBorder: true
          )
          .padding(.horizontal, 16)
      } else {
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 12) {
            ForEach(store.hotBattles) { battle in
              HotBattleCardView(battle: battle)
                .contentShape(Rectangle())
                .onTapGesture { send(.hotBattleTapped(battle)) }
            }
          }
          .padding(.horizontal, 16)
        }
      }
    }
  }

  @ViewBuilder
  private func bestCommentsSection() -> some View {
    VStack(alignment: .leading, spacing: 0) {
      HomeSectionHeader(title: "Best 댓글")
      VStack(spacing: 0) {
        ForEach(Array(store.bestComments.enumerated()), id: \.offset) { index, comment in
          HomeBestCommentRow(comment: comment)
            .contentShape(Rectangle())
            .onTapGesture { send(.bestCommentTapped(comment)) }
          if index < store.bestComments.count - 1 {
            PickeDivider(.cardBaseBorderDefault)
              .padding(.horizontal, 16)
          }
        }
      }
    }
  }

  @ViewBuilder
  private func bestBattlesSection() -> some View {
    VStack(alignment: .leading, spacing: 0) {
      HomeSectionHeader(title: "Best 배틀")
      VStack(spacing: 0) {
        ForEach(store.visibleBestBattles) { battle in
          BestBattleCardView(battle: battle)
            .contentShape(Rectangle())
            .onTapGesture { send(.bestBattleTapped(battle)) }
          PickeDivider(.cardBaseBorderDefault)
        }
      }
      .padding(.horizontal, 16)
    }
  }

  @ViewBuilder
  private func newBattlesSection() -> some View {
    VStack(alignment: .leading, spacing: 0) {
      HomeSectionHeader(title: "새로운 배틀")
      VStack(spacing: 12) {
        ForEach(store.newBattles) { battle in
          NewBattleCardView(battle: battle)
            .contentShape(Rectangle())
            .onTapGesture { send(.newBattleTapped(battle)) }
        }
      }
      .padding(.horizontal, 16)
      .padding(.bottom, 12)
    }
  }
}

#Preview {
  HomeView(
    store: Store(initialState: HomeFeature.State()) { HomeFeature() }
  )
}
