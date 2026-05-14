//
//  MainTabView.swift
//  MainTab
//
//  Created by Wonji Suh on 5/15/26.
//

import SwiftUI

import DesignSystem
import Home

import ComposableArchitecture

/// SwiftUI TabView + Picke 디자인 시스템 GNB 아이콘.
/// (TCAFlowTabRouter 는 systemImage 만 지원하므로, 커스텀 자산을 쓰기 위해 native TabView 사용)
public struct MainTabView: View {
  @Bindable private var store: StoreOf<MainTabCoordinator>

  public init(store: StoreOf<MainTabCoordinator>) {
    self.store = store
  }

  public var body: some View {
    TabView(
      selection: Binding(
        get: { store.selectedTab },
        set: { newValue in
          if newValue == store.selectedTab {
            store.send(.tabReselected(newValue))
          }
          store.send(.selectTab(newValue))
        }
      )
    ) {
      ForEach(MainTabCoordinator.Tab.allCases, id: \.rawValue) { tab in
        tabContent(for: tab)
          .tabItem { tabLabel(for: tab) }
          .tag(tab.rawValue)
      }
    }
    .tint(.primary500)
  }
}

extension MainTabView {
  private func tabLabel(for tab: MainTabCoordinator.Tab) -> some View {
    Label {
      Text(tab.title)
    } icon: {
      Image(asset: tab.iconAsset)
        .renderingMode(.template)
    }
  }

  @ViewBuilder
  private func tabContent(for tab: MainTabCoordinator.Tab) -> some View {
    switch tab {
    case .home:
      HomeCoordinatorView(
        store: store.scope(state: \.homeState, action: \.home)
      )

    case .explore:
      HomeCoordinatorView(
        store: store.scope(state: \.exploreState, action: \.explore)
      )

    case .quickBattle:
      HomeCoordinatorView(
        store: store.scope(state: \.quickBattleState, action: \.quickBattle)
      )

    case .myPage:
      HomeCoordinatorView(
        store: store.scope(state: \.myPageState, action: \.myPage)
      )
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
