//
//  RecapLockedView.swift
//  Profile
//
//  나의 철학자 유형 잠금 화면 — picke.pen `잠긴화면_콘텐츠 소비 5개 미만`.
//  분석 기록 부족 안내 카드 + 블러 처리된 성향 분석 + 잠금 해제 안내.
//

import SwiftUI

import DesignSystem
import Entity

struct RecapLockedView: View {
  /// 잠금 카드의 장식용 레이더(블러) 점수 — 실제 값 아님.
  private let placeholderScores = RecapScores(
    principle: 70, reason: 60, individual: 78, change: 45, inner: 65, ideal: 55
  )

  var body: some View {
    ScrollView {
      VStack(spacing: 24) {
        lockedCard
        tendencyLockedSection
      }
      .padding(.top, 20)
      .padding(.horizontal, 16)
      .padding(.bottom, 32)
    }
    .scrollIndicators(.hidden)
    .scrollBounceBehavior(.basedOnSize)
  }
}

private extension RecapLockedView {
  // MARK: 잠금 카드 (??형 + 안내)

  var lockedCard: some View {
    VStack(spacing: 24) {
      VStack(spacing: 6) {
        Text("나의 철학자 유형")
          .pretendardFont(family: .SemiBold, size: 13)
          .foregroundStyle(.primary500)
        Text("??형")
          .pretendardFont(family: .SemiBold, size: 24)
          .foregroundStyle(.gray500)
      }

      ZStack {
        Circle().fill(.beige600)
        Image(asset: .lock)
          .resizable()
          .scaledToFit()
          .frame(width: 30, height: 30)
      }
      .frame(width: 68, height: 68)
      .opacity(0.7)

      Text("아직 분석할 기록이 부족해요.\n배틀에 참여하면 성향을 확인할 수 있어요!")
        .pretendardFont(family: .SemiBold, size: 14)
        .foregroundStyle(.gray800)
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
    }
    .padding(.vertical, 16)
    .padding(.horizontal, 24)
    .frame(maxWidth: .infinity)
    .background(.beige50, in: RoundedRectangle(cornerRadius: 2))
    .overlay(
      RoundedRectangle(cornerRadius: 2)
        .stroke(.beige600, lineWidth: 1)
    )
    .overlay(alignment: .top) {
      Rectangle().fill(.primary500).frame(height: 3)
    }
    .clipShape(RoundedRectangle(cornerRadius: 2))
  }

  // MARK: 성향 분석 (블러 + 잠금 안내)

  var tendencyLockedSection: some View {
    VStack(spacing: 12) {
      Text("성향 분석")
        .pretendardFont(family: .SemiBold, size: 13)
        .foregroundStyle(.gray800)

      ZStack {
        RecapRadarChart(axes: placeholderScores.axes)
          .frame(height: 172)
          .opacity(0.4)
          .blur(radius: 4.375)
          .allowsHitTesting(false)

        Text("배틀 5개에 참여하시면\n잠금을 풀 수 있어요!")
          .pretendardFont(family: .SemiBold, size: 14)
          .foregroundStyle(.gray800)
          .multilineTextAlignment(.center)
      }
      .padding(.vertical, 16)
      .padding(.horizontal, 20)
      .frame(maxWidth: .infinity)
      .background(.beige50, in: RoundedRectangle(cornerRadius: 2))
      .overlay(
        RoundedRectangle(cornerRadius: 2)
          .stroke(.beige600, lineWidth: 1)
      )
      .clipShape(RoundedRectangle(cornerRadius: 2))
    }
  }
}
