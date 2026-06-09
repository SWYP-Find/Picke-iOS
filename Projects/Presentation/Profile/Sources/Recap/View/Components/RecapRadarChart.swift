//
//  RecapRadarChart.swift
//  Profile
//
//  성향 분석 6축 레이더(육각) 차트 — 데이터 폴리곤이 중심에서 펼쳐지는 애니메이션.
//

import SwiftUI

import DesignSystem
import Entity

public struct RecapRadarChart: View {
  private let axes: [RecapScoreAxis]
  private let rings: Int = 4

  @State private var progress: CGFloat = 0

  public init(axes: [RecapScoreAxis]) {
    self.axes = axes
  }

  public var body: some View {
    GeometryReader { geo in
      let side = min(geo.size.width, geo.size.height)
      let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
      let radius = side / 2 * 0.72

      ZStack {
        // 배경 그리드 (동심 육각형)
        ForEach(1 ... rings, id: \.self) { ring in
          polygon(center: center, radius: radius * CGFloat(ring) / CGFloat(rings))
            .stroke(.beige600, lineWidth: 1)
        }

        // 축 스포크
        ForEach(Array(axes.enumerated()), id: \.offset) { index, _ in
          Path { path in
            path.move(to: center)
            path.addLine(to: vertex(center: center, radius: radius, index: index))
          }
          .stroke(.beige600, lineWidth: 1)
        }

        // 데이터 폴리곤 (애니메이션)
        dataPolygon(center: center, radius: radius)
          .fill(.primary500.opacity(0.22))
        dataPolygon(center: center, radius: radius)
          .stroke(.primary500, lineWidth: 1.5)

        // 축 라벨
        ForEach(Array(axes.enumerated()), id: \.offset) { index, axis in
          Text(axis.label)
            .pretendardFont(family: .Medium, size: 10)
            .foregroundStyle(.gray500)
            .position(labelPosition(center: center, radius: radius, index: index))
        }
      }
      .onAppear {
        progress = 0
        withAnimation(.easeOut(duration: 0.8)) { progress = 1 }
      }
    }
  }
}

private extension RecapRadarChart {
  /// index 축의 각도(라디안). 12시 방향에서 시작해 시계 방향.
  func angle(for index: Int) -> CGFloat {
    let step = (2 * CGFloat.pi) / CGFloat(axes.count)
    return -CGFloat.pi / 2 + step * CGFloat(index)
  }

  func vertex(center: CGPoint, radius: CGFloat, index: Int) -> CGPoint {
    let a = angle(for: index)
    return CGPoint(x: center.x + radius * cos(a), y: center.y + radius * sin(a))
  }

  func labelPosition(center: CGPoint, radius: CGFloat, index: Int) -> CGPoint {
    let a = angle(for: index)
    let r = radius + 14
    return CGPoint(x: center.x + r * cos(a), y: center.y + r * sin(a))
  }

  /// 동심 육각형.
  func polygon(center: CGPoint, radius: CGFloat) -> Path {
    Path { path in
      for index in axes.indices {
        let p = vertex(center: center, radius: radius, index: index)
        if index == 0 { path.move(to: p) } else { path.addLine(to: p) }
      }
      path.closeSubpath()
    }
  }

  /// 점수 기반 데이터 폴리곤 (progress 로 중심→값 보간).
  func dataPolygon(center: CGPoint, radius: CGFloat) -> Path {
    Path { path in
      for (index, axis) in axes.enumerated() {
        let ratio = max(0, min(1, axis.value / 100)) * progress
        let p = vertex(center: center, radius: radius * ratio, index: index)
        if index == 0 { path.move(to: p) } else { path.addLine(to: p) }
      }
      path.closeSubpath()
    }
  }
}
