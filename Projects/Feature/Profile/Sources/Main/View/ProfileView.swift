//
//  ProfileView.swift
//  Profile
//

import SwiftUI

import FeatureSharedUI
import ComposableArchitecture
import PickeDesignKit
import PickeSharedUI

@ViewAction(for: ProfileFeature.self)
public struct ProfileView: View {
  @Bindable public var store: StoreOf<ProfileFeature>

  public init(store: StoreOf<ProfileFeature>) {
    self.store = store
  }

  public var body: some View {
    VStack(spacing: 0) {
      topBar()

      if store.viewState == .loading {
        ProfileSkeletonView()
      } else {
        // xr63n: 카드 그룹 ↔ 메뉴 그룹 gap 20
        VStack(spacing: 20) {
          // T3oil: 카드 3개 gap 16, 좌우 16
          VStack(spacing: 16) {
            profileCard()
            chargeButton()
            philosopherCard()
          }
          .padding(.horizontal, 16)

          // HFFUM: 메뉴 리스트 좌우 16
          menuList()
            .padding(.horizontal, 16)

          Spacer(minLength: 0)

          // 마이페이지 하단 네이티브 광고 — 2:1(.wide) 규격, 좌우 여백 16.
          AdFitNativeAdView(
            unit: .wide,
            insets: EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16),
            onAdClick: { send(.adNativeClicked) }
          )
        }
      }
    }
    .screenBackground()
    .toolbar(.hidden, for: .navigationBar)
    // 리워드 광고 사전 고지 — 디자인 시스템 커스텀 팝업.
    .customAlert($store.scope(state: \.rewardNoticeAlert, action: \.rewardNoticeAlert))
    .onAppear { send(.onAppear) }
  }
}

private extension ProfileView {
  // MARK: 상단 바 (알림 / 설정)

  @ViewBuilder
  func topBar() -> some View {
    HStack(spacing: 6) {
      Spacer()

      Button { send(.notificationTapped) } label: {
        bellIcon()
      }

      Button { send(.settingsTapped) } label: {
        Image(systemName: "gearshape")
          .font(.system(size: 20, weight: .regular))
          .foregroundStyle(.neutral900)
          .frame(width: 24, height: 24)
      }
    }
    .padding(.vertical, 20)
    .padding(.horizontal, 16)
  }

  @ViewBuilder
  func bellIcon() -> some View {
    if store.hasUnreadNotification {
      Image(asset: .bell)
        .resizable()
        .scaledToFit()
        .frame(width: 24, height: 24)
    } else {
      Image(systemName: "bell")
        .font(.system(size: 20, weight: .regular))
        .foregroundStyle(.neutral900)
        .frame(width: 24, height: 24)
    }
  }

  // MARK: 프로필 카드

  @ViewBuilder
  func profileCard() -> some View {
    Button {
      send(.profileTapped)
    } label: {
      HStack(spacing: 12) {
        avatar()

        VStack(alignment: .leading, spacing: 2) {
          Text(store.nickname)
            .pretendardFont(.headingMedium)
            .foregroundStyle(.gray800)

          Text("@\(store.userCode)")
            .pretendardFont(.regular13)
            .foregroundStyle(.gray300)
        }

        Spacer(minLength: 0)
      }
    }
    .buttonStyle(.plain)
  }

  @ViewBuilder
  func avatar() -> some View {
    // 디자인(oFtBQ): 항상 beige600 원 배경 위에 캐릭터 이미지/기본 아이콘을 올린다.
    ZStack {
      if let urlString = store.profileImageURL, let url = URL(string: urlString) {
        PickeRemoteImage(url: url) { EmptyView() }
          .content(.fit)
          .padding(4)
      } else {
        Image(systemName: "cat.fill")
          .font(.system(size: 24))
          .foregroundStyle(.gray300)
      }
    }
    .pickeAvatar(size: 52)
  }

  // MARK: 포인트 충전 버튼

  @ViewBuilder
  func chargeButton() -> some View {
    HStack(spacing: 6) {
      // 좌측(포인트 뱃지 + 보유 포인트) → 포인트 내역 상세
      Button {
        send(.chargePointTapped)
      } label: {
        HStack(spacing: 6) {
          ZStack {
            Circle().fill(.secondary300)
            Text("P")
              .pretendardFont(.bold11)
              .foregroundStyle(.gray800)
          }
          .frame(width: 24, height: 24)

          Text("내 포인트 \(store.point)")
            .pretendardFont(.semiBold12)
            .foregroundStyle(.beige50)

          Spacer(minLength: 8)
        }
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)

      // 무료 충전 → 리워드 광고
      Button {
        send(.freeChargeTapped)
      } label: {
        Text("무료 충전")
          .pretendardFont(.medium11)
          .foregroundStyle(.gray800)
          .padding(.vertical, 4)
          .padding(.horizontal, 6)
          .roundedBackground(.secondary300)
          .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
    }
    .padding(.vertical, 20)
    .padding(.horizontal, 16)
    .frame(maxWidth: .infinity)
    .roundedBackground(.primary800, radius: 8)
  }

  // MARK: 나의 철학자 유형

  @ViewBuilder
  func philosopherCard() -> some View {
    Button {
      send(.philosopherTapped)
    } label: {
      HStack(spacing: 12) {
        ZStack {
          RoundedRectangle(cornerRadius: 8)
            .fill(.beige200)
          if store.isPhilosopherLocked {
            // 배틀 5개 미만(미확정) → 잠금 이미지
            Image(asset: .lock)
              .resizable()
              .scaledToFit()
              .frame(width: 20, height: 20)
          } else if let urlString = store.philosopherImageURL, let url = URL(string: urlString) {
            PickeRemoteImage(url: url) { EmptyView() }
              .content(.fit)
              .padding(4)
          } else {
            Image(systemName: "brain.head.profile")
              .font(.system(size: 20))
              .foregroundStyle(.gray300)
          }
        }
        .frame(width: 40, height: 40)

        VStack(alignment: .leading, spacing: 4) {
          Text("나의 철학자 유형")
            .pretendardFont(.medium11)
            .foregroundStyle(.gray300)

          Text(store.philosopherDisplay)
            .pretendardFont(.headingSmall)
            .foregroundStyle(.gray700)
        }

        Spacer(minLength: 0)

        Image(systemName: "chevron.right")
          .font(.system(size: 13, weight: .semibold))
          .foregroundStyle(.neutral900)
      }
      .padding(16)
      .frame(maxWidth: .infinity)
      .pickeCard(
        .beige400,
        border: .beige600,
        radius: 8
      )
    }
    .buttonStyle(.plain)
  }

  // MARK: 메뉴 리스트

  @ViewBuilder
  func menuList() -> some View {
    VStack(spacing: 0) {
      ForEach(store.menuItems) { item in
        menuRow(item)
      }
    }
  }

  @ViewBuilder
  func menuRow(_ item: ProfileFeature.MenuItem) -> some View {
    Button {
      send(.menuTapped(item))
    } label: {
      HStack {
        Text(item.rawValue)
          .pretendardFont(.headingSmall)
          .foregroundStyle(.gray800)

        Spacer()

        Image(systemName: "chevron.right")
          .font(.system(size: 13, weight: .semibold))
          .foregroundStyle(.neutral900)
      }
      .padding(.vertical, 20)
      .contentShape(Rectangle())
      .bottomDivider(.beige600)
    }
    .buttonStyle(.plain)
  }
}
