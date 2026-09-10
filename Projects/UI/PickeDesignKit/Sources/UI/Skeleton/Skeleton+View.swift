//
//  Skeleton+View.swift
//  PickeDesignKit
//

import SwiftUI

// MARK: - View Extension

public extension View {
  /// 데이터가 오기 전 원본이 비어 크기를 잃는 경우 `width` / `height` 로 자리를 빌려준다.
  /// 로딩 중에만 적용되므로 데이터가 온 뒤의 동적 크기는 방해하지 않는다.
  func skeleton(
    isLoading: Bool,
    shape: SkeletonShape,
    width: CGFloat? = nil,
    height: CGFloat? = nil,
    base: Color = .beige600,
    highlight: Color = .beige50
  ) -> some View {
    modifier(
      SkeletonModifier(
        isLoading: isLoading,
        width: width,
        height: height,
        shape: shape,
        base: base,
        highlight: highlight
      )
    )
  }
}

// MARK: - Modifier

private struct SkeletonModifier: ViewModifier {
  /// 자리표시자가 나타나고 사라질 때의 페이드 길이(초).
  private static let fadeDuration: Double = 0.2

  let isLoading: Bool
  let width: CGFloat?
  let height: CGFloat?
  let shape: SkeletonShape
  let base: Color
  let highlight: Color

  func body(content: Content) -> some View {
    ZStack {
      content
        .opacity(isLoading ? 0 : 1)

      if isLoading {
        SkeletonView(shape, base: base, highlight: highlight)
          .frame(width: width, height: height)
          .transition(.opacity)
      }
    }
    .fixedSize(
      horizontal: isLoading && width != nil,
      vertical: isLoading && height != nil
    )
    .animation(.easeInOut(duration: Self.fadeDuration), value: isLoading)
  }
}
