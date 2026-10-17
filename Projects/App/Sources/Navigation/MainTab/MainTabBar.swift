//
//  MainTabBar.swift
//  Picke
//
//  Created by Picke on 10/17/26.
//

import ComposableArchitecture
import PickeDesignKit
import SwiftUI

struct MainTabBar: View {
  @Bindable var store: StoreOf<MainTabCoordinator>

  var body: some View {
    tabButtons()
      .padding(.horizontal, 21)
      .background {
        Color.white
          .ignoresSafeArea(.container, edges: .bottom)
          .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: -2)
      }
  }
}

extension MainTabBar {
  @ViewBuilder
  private func tabButtons() -> some View {
    HStack(spacing: 0) {
      ForEach(MainTabCoordinator.Tab.allCases, id: \.rawValue) { tab in
        tabButton(tab)
      }
    }
  }

  private func tabButton(_ tab: MainTabCoordinator.Tab) -> some View {
    Button {
      store.send(.tabTapped(tab.rawValue))
    } label: {
      tabLabel(tab)
    }
    .buttonStyle(.plain)
    .accessibilityLabel(tab.title)
    .accessibilityAddTraits(store.state.isSelected(tab) ? .isSelected : [])
    .accessibilityIdentifier("tab.\(tab.rawValue)")
  }

  @ViewBuilder
  private func tabLabel(_ tab: MainTabCoordinator.Tab) -> some View {
    VStack(spacing: 8) {
      Image(asset: tab.iconAsset(isSelected: store.state.isSelected(tab)))
        .renderingMode(.original)
        .resizable()
        .scaledToFit()
        .frame(width: 24, height: 24)
        .accessibilityHidden(true)

      Text(tab.title)
        .pretendardFont(.labelSmall)
        .foregroundStyle(store.state.isSelected(tab) ? .neutral900 : .gray200)
        .lineLimit(1)
        .frame(height: 16)
    }
    .padding(.top, 12)
    .padding(.bottom, 1)
    .frame(maxWidth: .infinity)
    .contentShape(Rectangle())
  }
}
