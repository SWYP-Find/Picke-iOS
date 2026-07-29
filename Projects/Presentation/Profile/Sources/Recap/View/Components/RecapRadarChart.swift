//
//  RecapRadarChart.swift
//  Profile
//

import SwiftUI

import Entity
import PickeDesignKit

public struct RecapRadarChart: View {
  private let axes: [RecapScoreAxis]
  private let rings: Int = 4

  /// picke.pen 육각형 단위 꼭짓점 (수직 반지름=1, 수평 0.846, 측면 y=±0.559).
  /// 순서: 원칙↑ · 이성 · 개인 · 변화↓ · 내면 · 이상 (axes 순서와 동일).
  private let unit: [CGPoint] = [
    CGPoint(x: 0, y: -1),
    CGPoint(x: 0.846, y: -0.559),
    CGPoint(x: 0.846, y: 0.559),
    CGPoint(x: 0, y: 1),
    CGPoint(x: -0.846, y: 0.559),
    CGPoint(x: -0.846, y: -0.559),
  ]

  @State private var progress: CGFloat = 0

  public init(axes: [RecapScoreAxis]) {
    self.axes = axes
  }

  public var body: some View {
    GeometryReader { geo in
      let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
      let radius = min(geo.size.width, geo.size.height) / 2 * 0.78
      let ratios = axes.map { clamp($0.value / 100) }

      ZStack {
        // 4겹 그리드 육각형
        ForEach(1 ... rings, id: \.self) { ring in
          hexPath(center: center, radius: radius * CGFloat(ring) / CGFloat(rings))
            .stroke(.beige600, lineWidth: 1)
        }

        // 스포크
        ForEach(unit.indices, id: \.self) { index in
          Path { path in
            path.move(to: center)
            path.addLine(to: vertex(center: center, radius: radius, index: index))
          }
          .stroke(.beige600, lineWidth: 1)
        }

        // 데이터 폴리곤 (animatableData 로 중심→값 실제 보간)
        RadarPolygon(ratios: ratios, unit: unit, progress: progress)
          .fill(.primary500.opacity(0.08))
        RadarPolygon(ratios: ratios, unit: unit, progress: progress)
          .stroke(.primary500, lineWidth: 1.5)

        // 꼭짓점 점 (6px)
        ForEach(Array(axes.enumerated()), id: \.offset) { index, axis in
          let ratio = clamp(axis.value / 100) * progress
          Circle()
            .fill(.primary500)
            .frame(width: 6, height: 6)
            .position(vertex(center: center, radius: radius * ratio, index: index))
        }

        // 축 라벨 (원칙: 600/neutral900, 나머지: 500/gray400)
        ForEach(Array(axes.enumerated()), id: \.offset) { index, axis in
          Text(axis.label)
            .pretendardFont(index == 0 ? .labelXSmall : .medium10)
            .foregroundStyle(index == 0 ? .neutral900 : .gray400)
            .fixedSize()
            .position(labelPosition(center: center, radius: radius, index: index))
        }
      }
      .onAppear {
        progress = 0
        withAnimation(.easeOut(duration: 0.9)) { progress = 1 }
      }
    }
  }
}

private extension RecapRadarChart {
  func clamp(_ value: Double) -> CGFloat {
    CGFloat(max(0, min(1, value)))
  }

  func vertex(center: CGPoint, radius: CGFloat, index: Int) -> CGPoint {
    let u = unit[index]
    return CGPoint(x: center.x + radius * u.x, y: center.y + radius * u.y)
  }

  func labelPosition(center: CGPoint, radius: CGFloat, index: Int) -> CGPoint {
    let u = unit[index]
    let r = radius + 16
    return CGPoint(x: center.x + r * u.x, y: center.y + r * u.y)
  }

  /// 단위 꼭짓점 기반 육각형.
  func hexPath(center: CGPoint, radius: CGFloat) -> Path {
    Path { path in
      for index in unit.indices {
        let p = vertex(center: center, radius: radius, index: index)
        if index == 0 { path.move(to: p) } else { path.addLine(to: p) }
      }
      path.closeSubpath()
    }
  }
}

/// 데이터 폴리곤 Shape — progress(animatableData)로 중심→값을 부드럽게 보간.
private struct RadarPolygon: Shape {
  let ratios: [CGFloat]
  let unit: [CGPoint]
  var progress: CGFloat

  var animatableData: CGFloat {
    get { progress }
    set { progress = newValue }
  }

  func path(in rect: CGRect) -> Path {
    let center = CGPoint(x: rect.midX, y: rect.midY)
    let radius = min(rect.width, rect.height) / 2 * 0.78
    var path = Path()
    for index in unit.indices {
      let r = radius * ratios[index] * progress
      let point = CGPoint(x: center.x + r * unit[index].x, y: center.y + r * unit[index].y)
      if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
    }
    path.closeSubpath()
    return path
  }
}
