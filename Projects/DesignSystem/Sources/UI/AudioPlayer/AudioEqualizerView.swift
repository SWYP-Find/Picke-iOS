//
//  AudioEqualizerView.swift
//  DesignSystem
//

import SwiftUI

public struct AudioEqualizerView: View {
  private let isPlaying: Bool
  private let barCount: Int
  private let barWidth: CGFloat
  private let spacing: CGFloat
  private let minHeight: CGFloat
  private let maxHeight: CGFloat
  private let color: Color

  @State private var animating = false

  public init(
    isPlaying: Bool,
    barCount: Int = 4,
    barWidth: CGFloat = 3,
    spacing: CGFloat = 2,
    minHeight: CGFloat = 6,
    maxHeight: CGFloat = 18,
    color: Color = .primary500
  ) {
    self.isPlaying = isPlaying
    self.barCount = barCount
    self.barWidth = barWidth
    self.spacing = spacing
    self.minHeight = minHeight
    self.maxHeight = maxHeight
    self.color = color
  }

  public var body: some View {
    HStack(alignment: .center, spacing: spacing) {
      ForEach(0 ..< barCount, id: \.self) { index in
        Capsule()
          .fill(color)
          .frame(width: barWidth, height: barHeight(for: index))
      }
    }
    .frame(height: maxHeight)
    .animation(
      isPlaying
        ? .easeInOut(duration: 0.45).repeatForever(autoreverses: true)
        : .default,
      value: animating
    )
    .onAppear { animating = isPlaying }
    .onChange(of: isPlaying) { _, newValue in
      animating = newValue
    }
  }

  /// 재생 중이면 막대마다 위상을 다르게 줘서 출렁이는 느낌을 낸다. 정지 시엔 최소 높이로 고정.
  private func barHeight(for index: Int) -> CGFloat {
    guard isPlaying, animating else { return minHeight }
    let ratios: [CGFloat] = [1.0, 0.55, 0.85, 0.4]
    let ratio = ratios[index % ratios.count]
    return minHeight + (maxHeight - minHeight) * ratio
  }
}
