//
//  RecapScoreBar.swift
//  Profile
//
//  성향 6축 점수 미니 바 — 채워지는 애니메이션.
//

import SwiftUI

import DesignSystem
import Entity

public struct RecapScoreBar: View {
  private let axis: RecapScoreAxis
  private let trackWidth: CGFloat = 48

  @State private var progress: CGFloat = 0

  public init(axis: RecapScoreAxis) {
    self.axis = axis
  }

  public var body: some View {
    HStack(spacing: 10) {
      Text(axis.label)
        .pretendardFont(family: .Medium, size: 10)
        .foregroundStyle(.neutral900)

      Spacer(minLength: 6)

      HStack(spacing: 6) {
        ZStack(alignment: .leading) {
          Capsule()
            .fill(.primary100)
            .frame(width: trackWidth, height: 4)
          Capsule()
            .fill(.primary500)
            .frame(width: trackWidth * ratio * progress, height: 4)
        }

        Text("\(Int(axis.value.rounded()))")
          .pretendardFont(family: .SemiBold, size: 11)
          .foregroundStyle(.neutral900)
      }
    }
    .padding(.vertical, 8)
    .padding(.horizontal, 12)
    .background(.beige400, in: RoundedRectangle(cornerRadius: 2))
    .onAppear {
      progress = 0
      withAnimation(.easeOut(duration: 0.7)) { progress = 1 }
    }
  }

  private var ratio: CGFloat {
    max(0, min(1, axis.value / 100))
  }
}
