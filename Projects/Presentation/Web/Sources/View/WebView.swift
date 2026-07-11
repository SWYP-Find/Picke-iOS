//
//  WebView.swift
//  Profile
//
//  Created by Wonji Suh  on 1/4/26.
//

import ComposableArchitecture
import DesignSystem
import SwiftUI

public struct WebView: View {
  @Bindable var store: StoreOf<WebReducer>

  public init(
    store: StoreOf<WebReducer>,
  ) {
    self.store = store
  }

  public var body: some View {
    ZStack {
      Color.beige50
        .edgesIgnoringSafeArea(.all)

      VStack {
        Spacer()
          .frame(height: 12)

        PickeNavigationBar(onBack: { store.send(.delegate(.backToRoot)) }) {
          Color.clear.frame(width: 24, height: 24)
        }
        .foregroundStyle(.neutral900)

        Spacer()
          .frame(height: 20)

        WebRepresentableView(urlToLoad: store.url)
          .edgesIgnoringSafeArea(.bottom)
      }
      .navigationBarBackButtonHidden(true)
    }
    .toolbar(.hidden, for: .navigationBar)
    .toolbar(.hidden, for: .tabBar)
  }
}
