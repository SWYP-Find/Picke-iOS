//
//  AudioEqualizerView.swift
//  PickeSharedUI
//
//  Created by Picke on 10/11/26.
//

import SwiftUI

import PickeDesignKit

/// Android `ChatBubblePlayingIndicator` — 막대 5개(폭 2.5, 높이 6/10/15/10/6, 간격 2, `iconPrimaryDefault`).
/// 막대마다 120ms 씩 늦게 0.6배 ↔ 최대 배율을 400ms 로 오간다.
public struct AudioEqualizerView: View {
  private static let barWidth: CGFloat = 2.5
  private static let barHeights: [CGFloat] = [6, 10, 15, 10, 6]
  private static let maxScales: [CGFloat] = [1.1, 1.3, 1.6, 1.3, 1.1]
  private static let minScale: CGFloat = 0.6

  @State private var isAnimating = false

  public init() {}

  public var body: some View {
    HStack(alignment: .center, spacing: 2) {
      ForEach(Self.barHeights.indices, id: \.self) { index in
        Capsule()
          .fill(.iconPrimaryDefault)
          .frame(width: Self.barWidth, height: Self.barHeights[index])
          .scaleEffect(
            x: 1,
            y: isAnimating ? Self.maxScales[index] : Self.minScale
          )
          .animation(
            .linear(duration: 0.4)
              .repeatForever(autoreverses: true)
              .delay(Double(index) * 0.12),
            value: isAnimating
          )
      }
    }
    .onAppear { isAnimating = true }
  }
}
