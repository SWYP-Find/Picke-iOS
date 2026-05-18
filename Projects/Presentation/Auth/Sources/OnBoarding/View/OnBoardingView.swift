//
//  OnBoardingView.swift
//  Auth
//
//  Created by Wonji Suh  on 5/15/26.
//

import SwiftUI

import DesignSystem

import ComposableArchitecture

public struct OnBoardingView: View {
  @Bindable var store: StoreOf<OnBoardingFeature>

  public init(store: StoreOf<OnBoardingFeature>) {
    self.store = store
  }

  public var body: some View {
    ZStack {
      Color.bgSubtle
        .edgesIgnoringSafeArea(.all)

      VStack(spacing: 0) {
        topSection()
          .frame(maxHeight: .infinity)

        bottomSection()
          .padding(.horizontal, 16)
          .padding(.bottom, 40)
      }
    }
  }
}

// MARK: - Sections

extension OnBoardingView {
  /// 상단: 타이틀 + 서브타이틀 + 일러스트 (페이지 스와이프 지원)
  @ViewBuilder
  private func topSection() -> some View {
    TabView(selection: $store.currentIndex) {
      ForEach(OnBoardingFeature.pages) { page in
        pageContent(page)
          .tag(page.id)
      }
    }
    .tabViewStyle(.page(indexDisplayMode: .never))
    .animation(.easeInOut(duration: 0.25), value: store.currentIndex)
  }

  @ViewBuilder
  private func pageContent(_ page: OnBoardingFeature.Page) -> some View {
    VStack(spacing: 40) {
      titleBlock(page)
      illustration(for: page)
    }
  }

  @ViewBuilder
  private func titleBlock(_ page: OnBoardingFeature.Page) -> some View {
    VStack(spacing: 12) {
      Text(page.title)
        .pretendardFont(family: .SemiBold, size: 24)
        .kerning(-0.6)
        .multilineTextAlignment(.center)
        .foregroundStyle(.neutral900)

      Text(page.subtitle)
        .pretendardFont(family: .Medium, size: 15)
        .lineSpacing(4)
        .multilineTextAlignment(.center)
        .foregroundStyle(.neutral300)
    }
    .padding(.top, 32)
    .padding(.horizontal, 16)
  }

  @ViewBuilder
  private func illustration(for page: OnBoardingFeature.Page) -> some View {
    Image(asset: page.imageAsset)
      .resizable()
      .scaledToFit()
      .frame(width: 319, height: 280)
  }

  /// 하단: indicator + CTA 버튼 (Frame 324)
  @ViewBuilder
  private func bottomSection() -> some View {
    VStack(spacing: 24) {
      OnBoardingPageIndicator(
        pageCount: OnBoardingFeature.pageCount,
        currentIndex: store.currentIndex
      )

      CustomButton(
        action: { store.send(.view(.primaryButtonTapped)) },
        title: store.primaryButtonTitle,
        config: CustomButtonConfig.primary(.large),
        isEnable: true
      )
    }
  }
}

#Preview {
  OnBoardingView(
    store: Store(initialState: OnBoardingFeature.State()) {
      OnBoardingFeature()
    }
  )
}
