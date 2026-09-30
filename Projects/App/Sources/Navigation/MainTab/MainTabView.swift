//
//  MainTabView.swift
//  Picke
//
//  Created by Codex on 7/11/26.
//

import ComposableArchitecture
import FeatureAssembly
import PickeCoreUI
import PickeDesignKit
import SwiftUI
import TCAFlow
import UIKit

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
        TabItem(
          title: $0.title,
          icon: $0.iconAsset(isSelected: false).rawValue,
          tag: $0.rawValue
        )
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
    .tint(.neutral900)
    .toolbar(store.shouldHideTabBar ? .hidden : .automatic, for: .tabBar)
  }
}

private extension MainTabView {
  static func configureTabBarAppearance() {
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

    configureItemAppearance(
      appearance.stackedLayoutAppearance,
      selectedColor,
      normalColor,
      font
    )
    configureItemAppearance(
      appearance.inlineLayoutAppearance,
      selectedColor,
      normalColor,
      font
    )
    configureItemAppearance(
      appearance.compactInlineLayoutAppearance,
      selectedColor,
      normalColor,
      font
    )

    UITabBar.appearance().standardAppearance = appearance
    UITabBar.appearance().scrollEdgeAppearance = appearance
    UITabBar.appearance().tintColor = selectedColor
    UITabBar.appearance().unselectedItemTintColor = normalColor
  }

  static func configureItemAppearance(
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

  func tabLabel(for tab: TabItem) -> some View {
    Label {
      Text(tab.title)
        .pretendardFont(.labelSmall)
    } icon: {
      tabIcon(for: tab)
    }
    .accessibilityIdentifier("tab.\(tab.tag)")
  }

  @ViewBuilder
  func tabIcon(for tab: TabItem) -> some View {
    let isSelected = store.selectedTab == tab.tag
    let asset = MainTabCoordinator.Tab(rawValue: tab.tag)?
      .iconAsset(isSelected: isSelected) ?? .none

    Image(asset: asset)
      .renderingMode(.template)
      .resizable()
      .scaledToFit()
      .frame(width: 24, height: 24)
  }

  /// TabView 는 네 탭의 콘텐츠를 한꺼번에 만들기 때문에, LazyView 로 감싸
  /// 각 탭이 처음 화면에 올라올 때까지 스토어 스코프와 뷰 생성을 미룬다.
  @ViewBuilder
  func tabContent(for tab: Int) -> some View {
    switch MainTabCoordinator.Tab(rawValue: tab) {
    case .home:
      LazyView {
        HomeCoordinatorView(
          store: store.scope(state: \.homeState, action: \.home)
        )
      }

    case .explore:
      LazyView {
        HifiCoordinatorView(
          store: store.scope(state: \.exploreState, action: \.explore)
        )
      }

    case .quickBattle:
      LazyView {
        BattleCoordinatorView(
          store: store.scope(state: \.quickBattleState, action: \.quickBattle)
        )
      }

    case .classroom:
      LazyView {
        ClassCoordinatorView(
          store: store.scope(state: \.classState, action: \.classroom)
        )
      }

    case .myPage:
      LazyView {
        ProfileCoordinatorView(
          store: store.scope(state: \.myPageState, action: \.myPage)
        )
      }

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
