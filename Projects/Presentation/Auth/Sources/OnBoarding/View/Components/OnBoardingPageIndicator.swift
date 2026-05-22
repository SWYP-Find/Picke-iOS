//
//  OnBoardingPageIndicator.swift
//  Auth
//
//  Created by Wonji Suh on 5/15/26.
//

import SwiftUI

import DesignSystem

/// 온보딩 페이지 인디케이터 — 활성 dot 은 pill (20×8), 비활성은 원형 (8×8)
public struct OnBoardingPageIndicator: View {
  private let pageCount: Int
  private let currentIndex: Int

  public init(
    pageCount: Int,
    currentIndex: Int
  ) {
    self.pageCount = pageCount
    self.currentIndex = currentIndex
  }

  public var body: some View {
    HStack(spacing: 12) {
      ForEach(0 ..< pageCount, id: \.self) { index in
        let isActive = index == currentIndex
        RoundedRectangle(cornerRadius: 4, style: .continuous)
          .fill(Color.neutral800)
          .opacity(isActive ? 1 : 0.4)
          .frame(width: isActive ? 20 : 8, height: 8)
          .animation(.easeInOut(duration: 0.2), value: currentIndex)
      }
    }
  }
}

#Preview {
  VStack(spacing: 16) {
    OnBoardingPageIndicator(pageCount: 4, currentIndex: 0)
    OnBoardingPageIndicator(pageCount: 4, currentIndex: 1)
    OnBoardingPageIndicator(pageCount: 4, currentIndex: 2)
    OnBoardingPageIndicator(pageCount: 4, currentIndex: 3)
  }
  .padding()
}
