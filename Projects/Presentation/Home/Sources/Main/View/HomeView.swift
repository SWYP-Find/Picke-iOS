//
//  HomeView.swift
//  Home
//
//  Created by Wonji Suh on 5/15/26.
//

import SwiftUI

import DesignSystem

import ComposableArchitecture

@ViewAction(for: HomeFeature.self)
public struct HomeView: View {
  @Bindable public var store: StoreOf<HomeFeature>

  public init(store: StoreOf<HomeFeature>) {
    self.store = store
  }

  public var body: some View {
    ZStack {
      Color.bgSubtle
        .edgesIgnoringSafeArea(.all)

      emptyPlaceholder()
    }
    .navigationTitle("홈")
    .onAppear { send(.onAppear) }
  }
}

extension HomeView {
  private func emptyPlaceholder() -> some View {
    VStack(spacing: 12) {
      Text("Home")
        .pretendardFont(family: .SemiBold, size: 24)
        .foregroundStyle(.neutral900)
      Text("오늘의 배틀과 큐레이팅이 표시될 자리입니다.")
        .pretendardFont(family: .Medium, size: 15)
        .foregroundStyle(.neutral300)
    }
  }
}

#Preview {
  HomeView(
    store: Store(initialState: HomeFeature.State()) { HomeFeature() }
  )
}
