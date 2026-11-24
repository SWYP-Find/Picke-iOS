//
//  HomeSkeletonView.swift
//  Home
//
//  Created by Picke on 5/16/26.
//

import PickeDesignKit
import SwiftUI

/// 첫 로딩 스켈레톤 — Android `HomeSkeleton` 구성.
/// 줄은 radius 4, 색은 surfaceBeigeStrong → surfaceBeigeDefault, 섹션 간격 24 / 40 / 16 / 16.
struct HomeSkeletonView: View {
  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      editorPickSkeleton()
      hotBattlesSkeleton()
        .padding(.top, 24)
      bestBattlesSkeleton()
        .padding(.top, 40)
      bestCommentsSkeleton()
        .padding(.top, 16)
      newBattlesSkeleton()
        .padding(.top, 16)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .allowsHitTesting(false)
  }
}

// MARK: - Sections

extension HomeSkeletonView {
  @ViewBuilder
  private func editorPickSkeleton() -> some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack(spacing: 0) {
        line(width: 70, height: 16)
        Spacer(minLength: 0)
        line(width: 32, height: 16)
      }
      .padding(16)
      block(.rect)
        .aspectRatio(1.8, contentMode: .fit)
      editorPickSubjectSkeleton()
        .padding(16)
    }
  }

  @ViewBuilder
  private func editorPickSubjectSkeleton() -> some View {
    VStack(alignment: .leading, spacing: 0) {
      line(width: 160, height: 20)
      line(width: 240, height: 16)
        .padding(.top, 4)
      line(width: 200, height: 16)
        .padding(.top, 4)
      HStack(spacing: 0) {
        line(width: 100, height: 14)
        Spacer(minLength: 0)
        line(width: 40, height: 14)
      }
      .padding(.top, 8)
    }
  }

  /// Android Row 는 두 번째 카드를 남은 폭(358 − 232 = 126)으로 줄인다 → 첫 카드만 220 고정.
  @ViewBuilder
  private func hotBattlesSkeleton() -> some View {
    VStack(alignment: .leading, spacing: 0) {
      line(width: 120, height: 20)
      HStack(alignment: .top, spacing: 12) {
        trendingCardSkeleton()
          .frame(width: 220)
        trendingCardSkeleton()
          .frame(maxWidth: 220)
      }
      .padding(.top, 12)
    }
    .padding(.horizontal, 16)
  }

  @ViewBuilder
  private func trendingCardSkeleton() -> some View {
    VStack(alignment: .leading, spacing: 12) {
      block(.round(cornerRadius: 4))
        .aspectRatio(1.2, contentMode: .fit)
      line(width: 160, height: 16)
    }
  }

  @ViewBuilder
  private func bestBattlesSkeleton() -> some View {
    VStack(alignment: .leading, spacing: 0) {
      line(width: 80, height: 20)
      VStack(alignment: .leading, spacing: 16) {
        ForEach(0 ..< 3, id: \.self) { _ in
          bestBattleRowSkeleton()
        }
      }
      .padding(.vertical, 16)
    }
    .padding(.horizontal, 16)
  }

  @ViewBuilder
  private func bestBattleRowSkeleton() -> some View {
    HStack(alignment: .top, spacing: 16) {
      block(.round(cornerRadius: 4))
        .frame(width: 24, height: 24)
      VStack(alignment: .leading, spacing: 8) {
        line(width: 200, height: 18)
        line(width: 100, height: 14)
      }
    }
  }

  @ViewBuilder
  private func bestCommentsSkeleton() -> some View {
    VStack(alignment: .leading, spacing: 0) {
      line(width: 80, height: 20)
      VStack(alignment: .leading, spacing: 16) {
        ForEach(0 ..< 3, id: \.self) { _ in
          bestCommentRowSkeleton()
        }
      }
      .padding(.vertical, 16)
    }
    .padding(.horizontal, 16)
  }

  @ViewBuilder
  private func bestCommentRowSkeleton() -> some View {
    VStack(alignment: .leading, spacing: 8) {
      line(width: 160, height: 14)
      line(width: 280, height: 14)
      line(width: 200, height: 14)
    }
  }

  @ViewBuilder
  private func newBattlesSkeleton() -> some View {
    VStack(alignment: .leading, spacing: 0) {
      line(width: 100, height: 20)
      VStack(spacing: 12) {
        ForEach(0 ..< 2, id: \.self) { _ in
          block(.round(cornerRadius: .radiusDefault))
            .frame(height: 120)
        }
      }
      .padding(.vertical, 12)
    }
    .padding(.horizontal, 16)
  }
}

// MARK: - Parts

extension HomeSkeletonView {
  /// Android `PickeSkeletonLine` — 폭은 최대값(좁은 자리에서는 줄어듦), radius 4.
  private func line(
    width: CGFloat,
    height: CGFloat
  ) -> some View {
    block(.round(cornerRadius: 4))
      .frame(maxWidth: width)
      .frame(height: height)
  }

  /// Android `Modifier.shimmer()` 기본 색.
  private func block(_ shape: SkeletonShape) -> some View {
    SkeletonView(
      shape,
      base: .surfaceBeigeStrong,
      highlight: .surfaceBeigeDefault
    )
  }
}
