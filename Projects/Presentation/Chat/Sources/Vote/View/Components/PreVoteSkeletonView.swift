//
//  PreVoteSkeletonView.swift
//  Chat
//
//  PreVoteView 의 로딩 상태 placeholder.
//  .pen `사전 투표창 - Skeleton Loader` 를 의미 단위(hero / 카피 / 옵션 / CTA) 로 재구성한다.
//

import SwiftUI

import DesignSystem

struct PreVoteSkeletonView: View {
  var body: some View {
    VStack(spacing: 0) {
      hero()
      contentSection()
      Spacer(minLength: 0)
      ctaButton()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    .background(Color.beige50.ignoresSafeArea())
  }
}

// MARK: - Hero

private extension PreVoteSkeletonView {
  @ViewBuilder
  func hero() -> some View {
    SkeletonView(cornerRadius: 6)
      .frame(height: 329)
      .overlay(alignment: .top) {
        SkeletonView(cornerRadius: 6)
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
      SkeletonView(cornerRadius: 6)
        .frame(width: 29, height: 17)
      SkeletonView(cornerRadius: 6)
        .frame(width: 49, height: 17)
    }
  }

  @ViewBuilder
  func titleBlock() -> some View {
    SkeletonView(cornerRadius: 6)
      .frame(width: 167, height: 68)
  }

  @ViewBuilder
  func summaryBlock() -> some View {
    SkeletonView(cornerRadius: 6)
      .frame(width: 235.5, height: 61.43)
  }

  @ViewBuilder
  func optionsRow() -> some View {
    ZStack {
      HStack(spacing: 8) {
        SkeletonView(cornerRadius: 6)
        SkeletonView(cornerRadius: 6)
      }
      .frame(height: 105.72)

      SkeletonView(cornerRadius: 7.5)
        .frame(width: 15, height: 15)
    }
  }
}

// MARK: - CTA

private extension PreVoteSkeletonView {
  @ViewBuilder
  func ctaButton() -> some View {
    SkeletonView(cornerRadius: 6)
      .frame(width: 87, height: 24)
      .padding(.bottom, 40)
  }
}
