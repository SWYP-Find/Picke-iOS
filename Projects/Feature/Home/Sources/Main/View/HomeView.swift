//
//  HomeView.swift
//  Home
//
//  Created by Picke on 5/15/26.
//

import SwiftUI

import HomeDomainInterface
import PickeDesignKit
import PickeSharedUI

import ComposableArchitecture
import FeatureSharedUI

@ViewAction(for: HomeFeature.self)
public struct HomeView: View {
  @Bindable public var store: StoreOf<HomeFeature>

  public init(store: StoreOf<HomeFeature>) {
    self.store = store
  }

  public var body: some View {
    VStack(spacing: 0) {
      HomeHeaderView(
        hasUnread: store.hasUnreadNotification,
        onNotificationTapped: { send(.notificationTapped) }
      ) // sticky — 스크롤 영향 없음

      ScrollView(showsIndicators: false) {
        if store.shouldShowSkeleton {
          HomeSkeletonView()
        } else if !store.hasVisibleHomeContent {
          emptyHomeSection()
        } else {
          VStack(spacing: 32) {
            if !store.heroes.isEmpty {
              HeroCarouselView(
                heroes: store.heroes,
                currentIndex: $store.heroIndex,
                onTap: { send(.heroTapped($0)) }
              )
            }

            hotBattlesSection()
            if !store.hotBattles.isEmpty || !store.bestBattles.isEmpty {
              adSection()
            }
            if !store.bestBattles.isEmpty {
              bestBattlesSection()
            }
            if !store.bestComments.isEmpty {
              bestCommentsSection()
            }
            if !store.newBattles.isEmpty {
              newBattlesSection()
            }
          }
          .padding(.bottom, 24)
        }
      }
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
    .navigationBarHidden(true)
    .scrollIndicators(.hidden)
    .scrollBounceBehavior(.basedOnSize)
  }
}

// MARK: - Sections

extension HomeView {
  @ViewBuilder
  private func emptyHomeSection() -> some View {
    VStack(spacing: 16) {
      Image(asset: .noDataLogo)
        .resizable()
        .scaledToFit()
        .frame(width: 160, height: 120)
      Text("아직 준비된 배틀이 없어요!")
        .pretendardFont(.bodyMedium)
        .foregroundStyle(.beige800)
    }
    .frame(maxWidth: .infinity)
    .frame(minHeight: 500)
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
    VStack(alignment: .leading, spacing: 12) {
      HomeSectionHeader(title: "지금 뜨는 배틀") {
        send(.seeMoreTapped(.hotBattles))
      }
      if store.hotBattles.isEmpty {
        Text("지금 뜨는 배틀이 아직 없어요")
          .pretendardFont(.bodyMedium)
          .foregroundStyle(.neutral300)
          .frame(width: 220, height: 274)
          .background(.beige50)
          .roundedBorder(.beige600, lineWidth: 1)
          .padding(.horizontal, 16)
      } else {
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 16) {
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
    VStack(alignment: .leading, spacing: 12) {
      HomeSectionHeader(title: "Best 댓글", onSeeMoreTapped: nil)
      VStack(spacing: 0) {
        ForEach(Array(store.bestComments.enumerated()), id: \.offset) { index, comment in
          HomeBestCommentRow(comment: comment)
            .contentShape(Rectangle())
            .onTapGesture { send(.bestCommentTapped(comment)) }
          if index < store.bestComments.count - 1 {
            PickeDivider(.beige600)
              .padding(.horizontal, 16)
          }
        }
      }
    }
  }

  @ViewBuilder
  private func bestBattlesSection() -> some View {
    VStack(alignment: .leading, spacing: 12) {
      HomeSectionHeader(title: "Best 배틀") {
        send(.seeMoreTapped(.bestBattles))
      }
      VStack(spacing: 0) {
        ForEach(Array(store.bestBattles.enumerated()), id: \.element.id) { index, battle in
          BestBattleCardView(battle: battle)
            .contentShape(Rectangle())
            .onTapGesture { send(.bestBattleTapped(battle)) }
          if index < store.bestBattles.count - 1 {
            PickeDivider(.beige600)
          }
        }
      }
      .padding(.horizontal, 16)
    }
  }

  @ViewBuilder
  private func newBattlesSection() -> some View {
    VStack(alignment: .leading, spacing: 16) {
      HomeSectionHeader(title: "새로운 배틀") {
        send(.seeMoreTapped(.newBattles))
      }
      VStack(spacing: 12) {
        ForEach(store.newBattles) { battle in
          NewBattleCardView(battle: battle)
            .contentShape(Rectangle())
            .onTapGesture { send(.newBattleTapped(battle)) }
        }
      }
      .padding(.horizontal, 16)
    }
  }
}

#Preview {
  HomeView(
    store: Store(initialState: HomeFeature.State()) { HomeFeature() }
  )
}
