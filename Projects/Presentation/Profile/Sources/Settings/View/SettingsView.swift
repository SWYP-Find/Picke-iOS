//
//  SettingsView.swift
//  Profile
//
//  설정 UI — picke.pen `설정`.
//  App Bar(백/타이틀) + 메뉴 리스트 + 로그아웃/탈퇴 확인 팝업.
//

import SwiftUI

import ComposableArchitecture
import DesignSystem

@ViewAction(for: SettingsFeature.self)
public struct SettingsView: View {
  @Bindable public var store: StoreOf<SettingsFeature>

  public init(store: StoreOf<SettingsFeature>) {
    self.store = store
  }

  public var body: some View {
    VStack(spacing: 0) {
      appBar()
      menuList()
      Spacer(minLength: 0)
    }
    .background(Color.beige200.ignoresSafeArea())
    .toolbar(.hidden, for: .navigationBar)
    .toolbar(.hidden, for: .tabBar)
    .customAlert($store.scope(state: \.customAlert, action: \.scope.customAlert))
  }
}

private extension SettingsView {
  // MARK: App Bar

  @ViewBuilder
  func appBar() -> some View {
    PickeNavigationBar(onBack: { send(.backTapped) }, centerTitle: "설정")
      .foregroundStyle(.gray500)
  }

  // MARK: 메뉴 리스트

  @ViewBuilder
  func menuList() -> some View {
    VStack(spacing: 0) {
      ForEach(store.menuItems) { item in
        menuRow(item)
      }
    }
    .padding(.top, 12)
    .padding(.horizontal, 16)
  }

  @ViewBuilder
  func menuRow(_ item: SettingsFeature.MenuItem) -> some View {
    Button {
      send(.menuTapped(item))
    } label: {
      HStack {
        Text(item.rawValue)
          .pretendardCustomFont(textStyle: .headingSmall)
          .foregroundStyle(item == .withdraw ? .gray500 : .gray800)

        Spacer()

        Image(systemName: "chevron.right")
          .font(.system(size: 13, weight: .semibold))
          .foregroundStyle(.neutral900)
      }
      .padding(.vertical, 20)
      .contentShape(Rectangle())
      .overlay(alignment: .bottom) {
        Rectangle().fill(.beige600).frame(height: 1)
      }
    }
    .buttonStyle(.plain)
  }
}
