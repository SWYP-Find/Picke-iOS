//
//  RecapLockedView.swift
//  Profile
//

import SwiftUI

import PickeDesignKit
import ProfileDomainInterface

struct RecapLockedView: View {
  /// 잠금 장식용 레이더(블러) — picke.pen 잠금 그래프 라벨/형태(거의 꽉 찬 육각형).
  private let placeholderAxes: [RecapScoreAxis] = [
    RecapScoreAxis(label: "원칙", value: 95),
    RecapScoreAxis(label: "논리", value: 88),
    RecapScoreAxis(label: "일관성", value: 85),
    RecapScoreAxis(label: "공감", value: 80),
    RecapScoreAxis(label: "실용", value: 88),
    RecapScoreAxis(label: "직관", value: 88),
  ]

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
          .pretendardFont(.semiBold13)
          .foregroundStyle(.primary500)
        Text("??형")
          .pretendardFont(.semiBold24)
          .foregroundStyle(.gray800)
      }

      ZStack {
        Circle().fill(.gray50)
        Image(asset: .lock)
          .resizable()
          .scaledToFit()
          .frame(width: 30, height: 30)
      }
      .frame(width: 68, height: 68)

      Text("아직 분석할 기록이 부족해요.\n배틀에 참여하면 성향을 확인할 수 있어요!")
        .pretendardFont(.headingSmall)
        .foregroundStyle(.gray800)
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
    }
    .padding(.vertical, 20)
    .frame(maxWidth: .infinity)
    .padding(.vertical, 16)
    .padding(.horizontal, 24)
    .pickeCard(.beige50, border: .beige600)
    .topDivider(.primary500, height: 3)
    .clipShape(RoundedRectangle(cornerRadius: .radiusDefault))
  }

  // MARK: 성향 분석 (블러 + 잠금 안내)

  var tendencyLockedSection: some View {
    VStack(spacing: 12) {
      Text("성향 분석")
        .pretendardFont(.semiBold13)
        .foregroundStyle(.gray800)

      ZStack {
        RecapRadarChart(axes: placeholderAxes)
          .frame(height: 172)
          .opacity(0.4)
          .blur(radius: 4.375)
          .allowsHitTesting(false)

        Text("배틀 5개에 참여하시면\n잠금을 풀 수 있어요!")
          .pretendardFont(.headingSmall)
          .foregroundStyle(.gray800)
          .multilineTextAlignment(.center)
      }
      .padding(.vertical, 16)
      .padding(.horizontal, 20)
      .frame(maxWidth: .infinity)
      .pickeCard(.beige50, border: .beige600)
      .clipShape(RoundedRectangle(cornerRadius: .radiusDefault))
    }
  }
}
