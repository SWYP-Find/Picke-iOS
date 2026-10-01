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
import PickeSharedUI
import SwiftUI
import TCAFlow

public struct MainTabView: View {
  @Bindable private var store: StoreOf<MainTabCoordinator>

  public init(store: StoreOf<MainTabCoordinator>) {
    PickeTabBarAppearance.configure()
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
    .toolbar(store.shouldHideTabBar ? .hidden : .visible, for: .tabBar)
  }
}

private extension MainTabView {
  @ViewBuilder
  func tabLabel(for tab: TabItem) -> some View {
    let isSelected = store.selectedTab == tab.tag
    let asset = MainTabCoordinator.Tab(rawValue: tab.tag)?
      .iconAsset(isSelected: isSelected) ?? .none

    PickeTabItemLabel(
      title: tab.title,
      icon: asset,
      tag: tab.tag
    )
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
