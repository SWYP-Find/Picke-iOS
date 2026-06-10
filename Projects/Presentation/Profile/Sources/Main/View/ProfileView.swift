//
//  ProfileView.swift
//  Profile
//
//  마이페이지 루트 UI — picke.pen `마이페이지_잠금`.
//  프로필 카드 + 포인트 충전 버튼 + 나의 철학자 유형 + 메뉴 리스트.
//

import SwiftUI

import ComposableArchitecture
import DesignSystem
import Kingfisher

@ViewAction(for: ProfileFeature.self)
public struct ProfileView: View {
  @Bindable public var store: StoreOf<ProfileFeature>

  public init(store: StoreOf<ProfileFeature>) {
    self.store = store
  }

  public var body: some View {
    VStack(spacing: 0) {
      topBar()

      if store.isLoading {
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
        }
      }
    }
    .background(Color.beige200.ignoresSafeArea())
    .toolbar(.hidden, for: .navigationBar)
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
        Image(systemName: "bell")
          .font(.system(size: 20, weight: .regular))
          .foregroundStyle(.neutral900)
          .frame(width: 24, height: 24)
          .overlay(alignment: .topTrailing) {
            if store.hasUnreadNotification {
              Circle()
                .fill(.errorDefault)
                .frame(width: 6, height: 6)
                .offset(x: 1, y: -1)
            }
          }
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
            .pretendardFont(family: .SemiBold, size: 16)
            .foregroundStyle(.gray800)

          Text("@\(store.userCode)")
            .pretendardFont(family: .Regular, size: 13)
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
      Circle().fill(.beige600)

      if let urlString = store.profileImageURL, let url = URL(string: urlString) {
        KFImage(url)
          .resizable()
          .scaledToFit()
          .padding(4)
      } else {
        Image(systemName: "cat.fill")
          .font(.system(size: 24))
          .foregroundStyle(.gray300)
      }
    }
    .frame(width: 52, height: 52)
    .clipShape(Circle())
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
              .pretendardFont(family: .Bold, size: 11)
              .foregroundStyle(.gray800)
          }
          .frame(width: 24, height: 24)

          Text("내 포인트 \(store.point)")
            .pretendardFont(family: .SemiBold, size: 12)
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
          .pretendardFont(family: .Medium, size: 11)
          .foregroundStyle(.gray800)
          .padding(.vertical, 4)
          .padding(.horizontal, 6)
          .background(.secondary300, in: RoundedRectangle(cornerRadius: 2))
          .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
    }
    .padding(.vertical, 20)
    .padding(.horizontal, 16)
    .frame(maxWidth: .infinity)
    .background(.primary800, in: RoundedRectangle(cornerRadius: 8))
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
            KFImage(url)
              .resizable()
              .scaledToFit()
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
            .pretendardFont(family: .Medium, size: 11)
            .foregroundStyle(.gray300)

          Text(store.philosopherDisplay)
            .pretendardFont(family: .SemiBold, size: 14)
            .foregroundStyle(.gray700)
        }

        Spacer(minLength: 0)

        Image(systemName: "chevron.right")
          .font(.system(size: 13, weight: .semibold))
          .foregroundStyle(.neutral900)
      }
      .padding(16)
      .frame(maxWidth: .infinity)
      .background(.beige400, in: RoundedRectangle(cornerRadius: 8))
      .overlay(
        RoundedRectangle(cornerRadius: 8)
          .stroke(.beige600, lineWidth: 1)
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
          .pretendardFont(family: .SemiBold, size: 14)
          .foregroundStyle(.gray800)

        Spacer()

        Image(systemName: "chevron.right")
          .font(.system(size: 13, weight: .semibold))
          .foregroundStyle(.neutral900)
      }
      .padding(.vertical, 20)
      .contentShape(Rectangle())
      .overlay(alignment: .bottom) {
        Rectangle()
          .fill(.beige600)
          .frame(height: 1)
      }
    }
    .buttonStyle(.plain)
  }
}
