//
//  AttendanceDayCell.swift
//  Home
//
//  주간 출석 카드의 요일 1칸. 상태에 따라 원의 표현이 4가지로 갈린다.
//

import SwiftUI

import AttendanceDomainInterface
import PickeDesignKit

struct AttendanceDayCell: View {
  let day: AttendanceDay
  /// 보상일(연속 성공 중인 주의 마지막 날) 여부는 셀 혼자 알 수 없어 부모가 판단해 넘긴다.
  let isStreakRewardDay: Bool

  private let circleSize: CGFloat = 36

  var body: some View {
    VStack(spacing: 4) {
      Text(day.day)
        .pretendardFont(.labelMedium)
        .foregroundStyle(.gray600)

      marker()
        .frame(width: circleSize, height: circleSize)
    }
  }

  @ViewBuilder
  private func marker() -> some View {
    switch day.status {
    case .attended:
      ZStack {
        Circle().fill(.primary500)
        Text("+\(day.points)P")
          .pretendardFont(.labelSmall)
          .foregroundStyle(.beige50)
      }

    case .missed:
      ZStack {
        Circle().fill(.beige600)
        Image(systemName: "xmark")
          .font(.system(size: 12))
          .foregroundStyle(.beige900)
      }

    case .upcoming:
      // 보상일이면 같은 점선 원 안에 선물 아이콘을 채워 강조한다.
      ZStack {
        if isStreakRewardDay {
          Circle().fill(.beige50)
          Image(systemName: "gift.fill")
            .font(.system(size: 20))
            .foregroundStyle(.primary500)
        }
        Circle()
          .strokeBorder(.beige700, style: StrokeStyle(lineWidth: 1, dash: [3]))
      }
    }
  }
}

#Preview {
  HStack(spacing: 12) {
    AttendanceDayCell(
      day: AttendanceDay(day: "월", date: "2026-07-20", status: .attended, points: 5),
      isStreakRewardDay: false
    )
    AttendanceDayCell(
      day: AttendanceDay(day: "화", date: "2026-07-21", status: .missed, points: 0),
      isStreakRewardDay: false
    )
    AttendanceDayCell(
      day: AttendanceDay(day: "수", date: "2026-07-22", status: .upcoming, points: 0),
      isStreakRewardDay: false
    )
    AttendanceDayCell(
      day: AttendanceDay(day: "일", date: "2026-07-26", status: .upcoming, points: 0),
      isStreakRewardDay: true
    )
  }
  .padding()
  .background(.beige100)
}
