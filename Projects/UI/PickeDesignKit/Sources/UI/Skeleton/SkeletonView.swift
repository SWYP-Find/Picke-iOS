//
//  SkeletonView.swift
//  PickeDesignKit
//

import SwiftUI

/// 로딩 중 콘텐츠 자리를 대신 채우는 시머 자리표시자.
public struct SkeletonView: View {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  private let shape: SkeletonShape
  private let baseColor: Color
  private let highlightColor: Color

  /// 기본값은 베이지 배경 기준이다. 어두운 표면에서는
  /// `base: .gray600, highlight: .gray400` 처럼 어두운 쌍을 넘긴다.
  public init(
    _ shape: SkeletonShape,
    base: Color = .beige600,
    highlight: Color = .beige50
  ) {
    self.shape = shape
    baseColor = base
    highlightColor = highlight
  }

  public var body: some View {
    shape
      .fill(baseColor)
      .overlay {
        GeometryReader {
          let size = $0.size
          let shimmerWidth = size.width / 2

          let blurRadius = max(shimmerWidth / 2, Self.minimumBlurRadius)
          let blurDiameter = blurRadius * 2

          let minX = -(shimmerWidth + blurDiameter)
          let maxX = size.width + shimmerWidth + blurDiameter

          // 모션 감소를 켠 사용자에게는 훑는 움직임 없이 바탕색만 보여준다.
          if !reduceMotion {
            // TimelineView 는 뷰가 다시 만들어져도 시각에서 위상을 다시 구하므로
            // onAppear 로 위상을 몰아주던 방식과 달리 애니메이션이 끊기지 않는다.
            TimelineView(.animation) { timeline in
              Rectangle()
                .fill(highlightColor)
                .frame(width: shimmerWidth, height: size.height * 2)
                .frame(height: size.height)
                .blur(radius: blurRadius)
                .rotationEffect(.degrees(Self.tiltDegrees))
                .blendMode(.softLight)
                .offset(x: minX + (maxX - minX) * Self.phase(at: timeline.date))
            }
          }
        }
      }
      .clipShape(shape)
      .compositingGroup()
      .accessibilityIdentifier("skeleton_root")
  }
}

private extension SkeletonView {
  /// 좁은 자리표시자에서도 번짐이 남도록 하는 최소 블러 반경.
  static let minimumBlurRadius: CGFloat = 30
  /// 하이라이트를 살짝 기울여 사선으로 훑게 한다.
  static let tiltDegrees: Double = 5
  /// 한 번 훑는 데 걸리는 시간(초).
  static let period: Double = 1

  static func phase(at date: Date) -> Double {
    date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: period) / period
  }
}
