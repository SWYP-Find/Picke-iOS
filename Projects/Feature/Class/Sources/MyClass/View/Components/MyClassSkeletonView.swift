//
//  MyClassSkeletonView.swift
//  Class
//

import PickeDesignKit
import SwiftUI

/// 내 클래스 목록 로딩 자리표시자. `MyClassRoomCard` 와 같은 자리에 블록을 둔다.
struct MyClassSkeletonView: View {
  var body: some View {
    VStack(spacing: 12) {
      ForEach(0 ..< 3, id: \.self) { _ in
        card()
      }
    }
    .allowsHitTesting(false)
  }
}

private extension MyClassSkeletonView {
  @ViewBuilder
  func card() -> some View {
    VStack(alignment: .leading, spacing: 12) {
      VStack(alignment: .leading, spacing: 12) {
        badgeRow()
        titleSection()
      }

      footer()
    }
    .padding(12)
    .frame(maxWidth: .infinity, alignment: .leading)
    .pickeCard(.beige50, border: .beige600)
  }

  @ViewBuilder
  func badgeRow() -> some View {
    HStack(spacing: 10) {
      bar(width: 44, height: 21)
      Spacer(minLength: 0)
      bar(width: 24, height: 24)
    }
  }

  @ViewBuilder
  func titleSection() -> some View {
    VStack(alignment: .leading, spacing: 4) {
      bar(width: 160, height: 21)
      bar(width: 220, height: 17)
    }
  }

  @ViewBuilder
  func footer() -> some View {
    HStack(spacing: 6) {
      bar(width: 180, height: 17)
      Spacer(minLength: 0)
      bar(width: 32, height: 17)
    }
    .padding(.top, 12)
    .overlay(alignment: .top) {
      Rectangle()
        .fill(.beige600)
        .frame(height: 1)
    }
  }

  func bar(
    width: CGFloat,
    height: CGFloat
  ) -> some View {
    SkeletonView(.round(cornerRadius: 2))
      .frame(width: width, height: height)
  }
}
