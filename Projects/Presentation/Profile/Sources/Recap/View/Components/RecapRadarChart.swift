//
//  RecapRadarChart.swift
//  Profile
//
//  성향 분석 6축 레이더 차트 — picke.pen `graph` 노드 정합.
//  세로로 약간 긴 육각형(폭/높이 = 0.846) + 4겹 그리드 + 스포크 + 데이터 폴리곤(중심→값 펼침 애니메이션) + 꼭짓점 점.
//

import SwiftUI

import DesignSystem
import Entity

public struct RecapRadarChart: View {
  private let axes: [RecapScoreAxis]
  private let rings: Int = 4

  /// picke.pen 육각형 단위 꼭짓점 (수직 반지름=1, 수평 0.846, 측면 y=±0.559).
  /// 순서: 원칙↑ · 이성 · 개인 · 변화↓ · 내면 · 직관 (axes 순서와 동일).
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

        // 데이터 폴리곤 (primary500 8% 채움 + 스트로크, 애니메이션)
        dataPath(center: center, radius: radius)
          .fill(.primary500.opacity(0.08))
        dataPath(center: center, radius: radius)
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
            .pretendardFont(family: index == 0 ? .SemiBold : .Medium, size: 10)
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

  /// 점수 기반 데이터 폴리곤 (progress 로 중심→값 보간).
  func dataPath(center: CGPoint, radius: CGFloat) -> Path {
    Path { path in
      for (index, axis) in axes.enumerated() {
        let ratio = clamp(axis.value / 100) * progress
        let p = vertex(center: center, radius: radius * ratio, index: index)
        if index == 0 { path.move(to: p) } else { path.addLine(to: p) }
      }
      path.closeSubpath()
    }
  }
}
