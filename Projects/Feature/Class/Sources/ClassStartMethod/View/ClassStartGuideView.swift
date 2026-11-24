//
//  ClassStartGuideView.swift
//  Class
//
//  Created by Picke on 10/12/26.
//

import ComposableArchitecture
import PickeDesignKit
import SwiftUI

public struct ClassStartGuideView: View {
  @Bindable public var store: StoreOf<ClassStartGuideFeature>

  public init(store: StoreOf<ClassStartGuideFeature>) {
    self.store = store
  }

  public var body: some View {
    GeometryReader { geometry in
      ZStack(alignment: .bottom) {
        Color.clear
          .ignoresSafeArea()
          .contentShape(Rectangle())
          .onTapGesture { store.send(.dismissTapped) }
          .accessibilityHidden(true)

        ViewThatFits(in: .vertical) {
          sheetContent()
          ScrollView(.vertical) {
            sheetContent()
          }
          .scrollIndicators(.hidden)
          .frame(maxHeight: geometry.size.height)
        }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
        .accessibilityAction(.escape) { store.send(.dismissTapped) }
      }
    }
  }
}

private extension ClassStartGuideView {
  @ViewBuilder
  func sheetContent() -> some View {
    VStack(spacing: 0) {
      Capsule()
        .fill(.gray50)
        .frame(width: 40, height: 4)
        .frame(maxWidth: .infinity)

      Text(store.title)
        .pretendardFont(.semiBold24)
        .foregroundStyle(.gray800)
        .frame(maxWidth: .infinity, minHeight: 31, alignment: .leading)
        .padding(.top, 32)

      guideCard()
        .padding(.top, 20)

      Button { store.send(.dismissTapped) } label: {
        Text("확인했어요")
      }
      .ctaButtonStyle(.primary, size: .large, height: 52)
      .padding(.top, 28)
    }
    .padding(.top, 12)
    .padding(.horizontal, 16)
    .padding(.bottom, 16)
    .frame(maxWidth: .infinity)
    .background(
      UnevenRoundedRectangle(topLeadingRadius: 26, topTrailingRadius: 26)
        .fill(.beige50)
        .ignoresSafeArea(edges: .bottom)
    )
  }

  @ViewBuilder
  func guideCard() -> some View {
    VStack(spacing: 0) {
      Image(asset: store.illustration)
        .resizable()
        .aspectRatio(370.0 / 154.0, contentMode: .fit)
        .frame(maxWidth: .infinity)
        .clipped()
        .accessibilityHidden(true)

      Text(store.headline)
        .pretendardFont(.headingMedium)
        .foregroundStyle(.gray800)
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity, minHeight: 24)
        .padding(.top, 20)

      Text(store.description)
        .pretendardFont(.bodyMedium)
        .foregroundStyle(.gray400)
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity, minHeight: 20)
        .padding(.top, 8)
    }
    .padding(.top, 16)
    .padding(.bottom, 16)
    .background(.beige200)
  }
}
