//
//  SplashView.swift
//  Splash
//
//  Created by Wonji Suh  on 5/6/26.
//

import ComposableArchitecture
import SwiftUI

import PickeAnimation
import PickeDesignKit

public struct SplashView: View {
  @Bindable var store: StoreOf<SplashFeature>

  public init(
    store: StoreOf<SplashFeature>
  ) {
    self.store = store
  }

  public var body: some View {
    ZStack {
      Color.primary500
        .edgesIgnoringSafeArea(.all)

      VStack {
        Spacer()

        SplashLogoAnimation()
          .equatable()

        Spacer()
      }
    }
    .onAppear {
      store.send(.view(.onAppear))
    }
    .alert($store.scope(state: \.alert, action: \.alert))
  }
}

/// 저장 프로퍼티가 없어 합성된 `==` 가 항상 참이다.
/// `.equatable()` 과 함께 부모가 갱신돼도 GIF 를 다시 그리지 않게 막는다.
private struct SplashLogoAnimation: View, Equatable {
  private static let logoSize = CGSize(width: 250, height: 250)

  var body: some View {
    PickeAnimatedImageView(.splashLogo, size: Self.logoSize)
  }
}
