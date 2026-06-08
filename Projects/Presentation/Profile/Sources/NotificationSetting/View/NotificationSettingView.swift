//
//  NotificationSettingView.swift
//  Profile
//
//  알림 설정 UI — picke.pen `알림 설정`.
//  App Bar + 섹션(기능별/소셜/마케팅) + 토글 행.
//

import SwiftUI

import ComposableArchitecture
import DesignSystem
import Entity

@ViewAction(for: NotificationSettingFeature.self)
public struct NotificationSettingView: View {
  @Bindable public var store: StoreOf<NotificationSettingFeature>

  public init(store: StoreOf<NotificationSettingFeature>) {
    self.store = store
  }

  public var body: some View {
    VStack(spacing: 0) {
      PickeNavigationBar(onBack: { send(.backTapped) }, centerTitle: "알림 설정")
        .foregroundStyle(.gray500)

      if store.isLoading {
        NotificationSettingSkeletonView()
      } else {
        ScrollView {
          VStack(spacing: 20) {
            ForEach(NotificationSettingSection.allCases) { section in
              sectionView(section)
            }
          }
          .padding(.vertical, 20)
          .padding(.horizontal, 16)
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
      }
    }
    .background(Color.beige200.ignoresSafeArea())
    .toolbar(.hidden, for: .navigationBar)
    .toolbar(.hidden, for: .tabBar)
    .onAppear { send(.onAppear) }
  }
}

private extension NotificationSettingView {
  @ViewBuilder
  func sectionView(_ section: NotificationSettingSection) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(section.title)
        .pretendardFont(family: .SemiBold, size: 12)
        .foregroundStyle(.gray300)

      VStack(spacing: 0) {
        ForEach(section.keys) { key in
          settingRow(key)
        }
      }
    }
  }

  @ViewBuilder
  func settingRow(_ key: NotificationSettingKey) -> some View {
    HStack(spacing: 4) {
      VStack(alignment: .leading, spacing: 4) {
        Text(key.title)
          .pretendardFont(family: .Medium, size: 13)
          .foregroundStyle(.gray800)

        Text(key.subtitle)
          .pretendardFont(family: .Regular, size: 11)
          .foregroundStyle(.gray300)
      }

      Spacer(minLength: 8)

      Button {
        send(.toggle(key))
      } label: {
        NotificationToggle(isOn: store.settings.isOn(key))
      }
      .buttonStyle(.plain)
    }
    .padding(.vertical, 16)
    .overlay(alignment: .bottom) {
      Rectangle().fill(.beige600).frame(height: 1)
    }
  }
}

/// picke.pen 토글 (32×18, ON=primary500 / OFF=neutral200, knob 14).
private struct NotificationToggle: View {
  let isOn: Bool

  var body: some View {
    ZStack(alignment: isOn ? .trailing : .leading) {
      Capsule()
        .fill(isOn ? Color.primary500 : Color.neutral200)

      Circle()
        .fill(.beige50)
        .frame(width: 14, height: 14)
        .padding(2)
    }
    .frame(width: 32, height: 18)
    .animation(.easeInOut(duration: 0.15), value: isOn)
  }
}
