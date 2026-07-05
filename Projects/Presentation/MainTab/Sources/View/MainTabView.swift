//
//  MainTabView.swift
//  MainTab
//
//  Created by Wonji Suh on 5/15/26.
//

import SwiftUI
import UIKit

import Battle
import DesignSystem
import Hifi
import Home
import Profile
import TCAFlow

import ComposableArchitecture

public struct MainTabView: View {
  @Bindable private var store: StoreOf<MainTabCoordinator>

  public init(store: StoreOf<MainTabCoordinator>) {
    Self.configureTabBarAppearance()
    self.store = store
  }

  public var body: some View {
    TCAFlowTabRouter(
      selectedTab: $store.selectedTab.sending(\.selectTab),
      tabs: MainTabCoordinator.Tab.allCases.map {
        TabItem(title: $0.title, icon: $0.iconAsset(isSelected: false).rawValue, tag: $0.rawValue)
      },
      onReselect: { tab in
        store.send(.tabReselected(tab))
      },
      tabItemLabel: { tab in
        tabLabel(for: tab)
      }
    ) {
      tabContent(for: $0)
    }
    // 기본/선택 색은 UITabBarAppearance 와 tint 가 제어.
    .tint(.neutral900)
  }
}

extension MainTabView {
  private static func configureTabBarAppearance() {
    let selectedColor = UIColor.neutral900
    let normalColor = UIColor.gray200
    let backgroundColor = UIColor.bgDefault
    let borderColor = UIColor.borderDefault.withAlphaComponent(0.4)
    let font = UIFont.pretendardFontFamily(family: .Medium, size: 12)

    let appearance = UITabBarAppearance()
    appearance.configureWithOpaqueBackground()
    appearance.backgroundColor = backgroundColor
    appearance.shadowColor = borderColor
    appearance.selectionIndicatorImage = UIImage()

    configureItemAppearance(appearance.stackedLayoutAppearance, selectedColor, normalColor, font)
    configureItemAppearance(appearance.inlineLayoutAppearance, selectedColor, normalColor, font)
    configureItemAppearance(appearance.compactInlineLayoutAppearance, selectedColor, normalColor, font)

    UITabBar.appearance().standardAppearance = appearance
    UITabBar.appearance().scrollEdgeAppearance = appearance
    UITabBar.appearance().tintColor = selectedColor
    UITabBar.appearance().unselectedItemTintColor = normalColor
  }

  private static func configureItemAppearance(
    _ itemAppearance: UITabBarItemAppearance,
    _ selectedColor: UIColor,
    _ normalColor: UIColor,
    _ font: UIFont
  ) {
    itemAppearance.normal.iconColor = normalColor
    itemAppearance.normal.titleTextAttributes = [
      .font: font,
      .foregroundColor: normalColor,
    ]

    itemAppearance.selected.iconColor = selectedColor
    itemAppearance.selected.titleTextAttributes = [
      .font: font,
      .foregroundColor: selectedColor,
    ]
  }

  @ViewBuilder
  private func tabLabel(for tab: TabItem) -> some View {
    Label {
      Text(tab.title)
        .pretendardFont(.labelSmall)
    } icon: {
      tabIcon(for: tab)
    }
    .accessibilityIdentifier("tab.\(tab.tag)")
  }

  @ViewBuilder
  private func tabIcon(for tab: TabItem) -> some View {
    let isSelected = store.selectedTab == tab.tag
    let asset = MainTabCoordinator.Tab(rawValue: tab.tag)?
      .iconAsset(isSelected: isSelected) ?? .none

    Image(asset: asset)
      .renderingMode(.template)
      .resizable()
      .scaledToFit()
      .frame(width: 24, height: 24)
  }

  @ViewBuilder
  private func tabContent(for tab: Int) -> some View {
    switch MainTabCoordinator.Tab(rawValue: tab) {
    case .home:
      HomeCoordinatorView(
        store: store.scope(state: \.homeState, action: \.home)
      )

    case .explore:
      HifiCoordinatorView(
        store: store.scope(state: \.exploreState, action: \.explore)
      )

    case .quickBattle:
      BattleCoordinatorView(
        store: store.scope(state: \.quickBattleState, action: \.quickBattle)
      )

    case .myPage:
      ProfileCoordinatorView(
        store: store.scope(state: \.myPageState, action: \.myPage)
      )

    case .none:
      EmptyView()
    }
  }
}

#Preview {
  MainTabView(
    store: Store(initialState: MainTabCoordinator.State()) {
      MainTabCoordinator()
    }
  )
}
