//
//  BattleView.swift
//  Battle
//
//  빠른 배틀 탭 루트 UI. (스캐폴딩 — #8 오늘의 배틀 구현 시 콘텐츠 채움)
//

import SwiftUI

import ComposableArchitecture
import DesignSystem
import Entity

@ViewAction(for: BattleFeature.self)
public struct BattleView: View {
  public let store: StoreOf<BattleFeature>

  public init(store: StoreOf<BattleFeature>) {
    self.store = store
  }

  public var body: some View {
    VStack(spacing: 0) {
      content()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.beige200.ignoresSafeArea())
    .navigationBarHidden(true)
    .toolbar(.hidden, for: .navigationBar)
    .onAppear { send(.onAppear) }
  }
}

private extension BattleView {
  @ViewBuilder
  func content() -> some View {
    VStack(spacing: 8) {
      Image(asset: .noDataLogo)
        .resizable()
        .scaledToFit()
        .frame(width: 135, height: 90)

      Text("빠른 배틀 준비 중입니다")
        .pretendardCustomFont(textStyle: .bodyMedium)
        .foregroundStyle(.beige800)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}
