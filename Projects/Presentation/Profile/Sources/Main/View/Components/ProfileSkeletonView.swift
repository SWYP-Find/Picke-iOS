//
//  ProfileSkeletonView.swift
//  Profile
//
//  마이페이지 로딩 스켈레톤 — 라이트(beige) 배경에 맞춘 옅은 shimmer.
//

import SwiftUI

import DesignSystem

struct ProfileSkeletonView: View {
  var body: some View {
    VStack(spacing: 20) {
      // 프로필 카드 자리
      HStack(spacing: 12) {
        block(width: 52, height: 52, radius: 26)
        VStack(alignment: .leading, spacing: 8) {
          block(width: 140, height: 16)
          block(width: 80, height: 13)
        }
        Spacer(minLength: 0)
      }
      .padding(.horizontal, 16)

      VStack(spacing: 16) {
        block(maxWidth: true, height: 64, radius: 8) // 포인트 충전 버튼
        block(maxWidth: true, height: 72, radius: 8) // 나의 철학자 유형
      }
      .padding(.horizontal, 16)

      // 메뉴 리스트 자리
      VStack(spacing: 0) {
        ForEach(0 ..< 3, id: \.self) { _ in
          HStack {
            block(width: 100, height: 16)
            Spacer()
          }
          .padding(.vertical, 20)
          .overlay(alignment: .bottom) {
            Rectangle().fill(.beige600).frame(height: 1)
          }
        }
      }
      .padding(.horizontal, 16)

      Spacer(minLength: 0)
    }
  }

  @ViewBuilder
  private func block(
    width: CGFloat? = nil,
    maxWidth: Bool = false,
    height: CGFloat,
    radius: CGFloat = 4
  ) -> some View {
    LightSkeletonBlock(cornerRadius: radius)
      .frame(width: width)
      .frame(maxWidth: maxWidth ? .infinity : nil)
      .frame(height: height)
  }
}

/// 라이트 배경용 skeleton 블록 (옅은 회색 base + 흰색 shimmer).
private struct LightSkeletonBlock: View {
  let cornerRadius: CGFloat

  @State private var phase: CGFloat = -1

  private let baseColor = Color.black.opacity(0.06)
  private let shimmerColor = Color.white.opacity(0.55)

  var body: some View {
    RoundedRectangle(cornerRadius: cornerRadius)
      .fill(baseColor)
      .overlay {
        LinearGradient(
          stops: [
            .init(color: shimmerColor.opacity(0), location: 0),
            .init(color: shimmerColor, location: 0.5),
            .init(color: shimmerColor.opacity(0), location: 1),
          ],
          startPoint: UnitPoint(x: phase, y: 0.5),
          endPoint: UnitPoint(x: phase + 1, y: 0.5)
        )
      }
      .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
      .onAppear {
        withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
          phase = 2
        }
      }
  }
}
