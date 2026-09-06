//
//  PreVoteSkeletonView.swift
//  Chat
//

import SwiftUI

import PickeDesignKit

struct PreVoteSkeletonView: View {
  /// 사후(최종) 투표 — 어두운 화면과 이어지도록 배경을 검정으로.
  var isDark: Bool = false

  /// 다크 배경에선 shimmer 도 어두운 톤으로 (안드로이드 VoteScreen: base neutral600 / highlight neutral400).
  private func bar(cornerRadius: CGFloat) -> SkeletonView {
    isDark
      ? SkeletonView(cornerRadius: cornerRadius, baseColor: .neutral600, shimmerColor: .neutral400)
      : SkeletonView(cornerRadius: cornerRadius)
  }

  var body: some View {
    VStack(spacing: 0) {
      hero()
      contentSection()
      Spacer(minLength: 0)
      ctaButton()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    .background((isDark ? Color.black : Color.beige50).ignoresSafeArea())
  }
}

// MARK: - Hero

private extension PreVoteSkeletonView {
  @ViewBuilder
  func hero() -> some View {
    bar(cornerRadius: 6)
      .frame(height: 329)
      .overlay(alignment: .top) {
        bar(cornerRadius: 6)
          .frame(height: 60)
          .padding(.top, 70)
      }
  }
}

// MARK: - Content

private extension PreVoteSkeletonView {
  @ViewBuilder
  func contentSection() -> some View {
    VStack(alignment: .leading, spacing: 16) {
      tagsRow()
      titleBlock()
      summaryBlock()
      optionsRow()
    }
    .padding(.horizontal, 16)
    .padding(.top, 24)
  }

  @ViewBuilder
  func tagsRow() -> some View {
    HStack(spacing: 8) {
      bar(cornerRadius: 6)
        .frame(width: 29, height: 17)
      bar(cornerRadius: 6)
        .frame(width: 49, height: 17)
    }
  }

  @ViewBuilder
  func titleBlock() -> some View {
    bar(cornerRadius: 6)
      .frame(width: 167, height: 68)
  }

  @ViewBuilder
  func summaryBlock() -> some View {
    bar(cornerRadius: 6)
      .frame(width: 235.5, height: 61.43)
  }

  @ViewBuilder
  func optionsRow() -> some View {
    ZStack {
      HStack(spacing: 8) {
        bar(cornerRadius: 6)
        bar(cornerRadius: 6)
      }
      .frame(height: 105.72)

      bar(cornerRadius: 7.5)
        .frame(width: 15, height: 15)
    }
  }
}

// MARK: - CTA

private extension PreVoteSkeletonView {
  @ViewBuilder
  func ctaButton() -> some View {
    bar(cornerRadius: 6)
      .frame(width: 87, height: 24)
      .padding(.bottom, 40)
  }
}
