//
//  HifiView.swift
//  Hifi
//

import SwiftUI

import ComposableArchitecture
import DesignSystem

@ViewAction(for: HifiFeature.self)
public struct HifiView: View {
  public let store: StoreOf<HifiFeature>

  public init(store: StoreOf<HifiFeature>) {
    self.store = store
  }

  public var body: some View {
    VStack(spacing: 12) {
      Image(systemName: "waveform")
        .font(.system(size: 40, weight: .regular))
        .foregroundStyle(.primary500)
      Text("Hi-Fi")
        .pretendardFont(family: .SemiBold, size: 18)
        .foregroundStyle(.neutral800)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.beige200.ignoresSafeArea())
    .navigationBarHidden(true)
    .onAppear { send(.onAppear) }
  }
}
