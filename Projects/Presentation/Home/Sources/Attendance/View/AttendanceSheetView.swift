//
//  AttendanceSheetView.swift
//  Home
//

import SwiftUI

import AttendanceDomainInterface
import PickeDesignKit

public struct AttendanceSheetView: View {
  private let weekly: WeeklyAttendance
  /// 오늘 획득한 포인트. 주간 데이터와 별개로 표기되어 별도 파라미터로 받는다.
  private let pointsEarned: Int

  public init(weekly: WeeklyAttendance, pointsEarned: Int) {
    self.weekly = weekly
    self.pointsEarned = pointsEarned
  }

  public var body: some View {
    VStack(spacing: 20) {
      dragHandle()
      titleBlock()
      weeklyCard()
      footerBlock()
    }
    .frame(maxWidth: .infinity)
    .padding(.top, 16)
    .padding(.horizontal, 16)
    .padding(.bottom, 40)
    .background(
      UnevenRoundedRectangle(
        topLeadingRadius: 32,
        topTrailingRadius: 32
      )
      .fill(.white)
      .ignoresSafeArea(edges: .bottom)
    )
  }

  @ViewBuilder
  private func dragHandle() -> some View {
    RoundedRectangle(cornerRadius: 2)
      .fill(.gray50)
      .frame(width: 40, height: 4)
      .padding(.bottom, 10)
  }

  @ViewBuilder
  private func titleBlock() -> some View {
    VStack(spacing: 6) {
      Text("오늘의 출석체크 성공")
        .pretendardFont(.semiBold24)
        .foregroundStyle(.gray900)

      Text("픽케에 매일 출석하고 포인트를 모아 보세요")
        .pretendardFont(.bodyMedium)
        .foregroundStyle(.gray400)
    }
    .multilineTextAlignment(.center)
  }

  @ViewBuilder
  private func weeklyCard() -> some View {
    VStack(spacing: 24) {
      HStack {
        streakBadge()
        Spacer()
        earnedPoints()
      }

      HStack(spacing: 0) {
        ForEach(weekly.days) { day in
          AttendanceDayCell(
            day: day,
            isStreakRewardDay: isStreakRewardDay(day)
          )
          .frame(maxWidth: .infinity)
        }
      }
    }
    .padding(.top, 20)
    .padding(.bottom, 24)
    .padding(.horizontal, 20)
    .background(
      RoundedRectangle(cornerRadius: 6)
        .fill(.beige100)
        .overlay(
          RoundedRectangle(cornerRadius: 6)
            .stroke(.gray50, lineWidth: 1)
        )
    )
  }

  /// 마지막 날(일요일)이 아직 오지 않았고 연속이 끊기지 않았을 때만 보상일로 강조한다.
  private func isStreakRewardDay(_ day: AttendanceDay) -> Bool {
    guard weekly.isStreakAlive, day.status == .upcoming else { return false }
    return weekly.days.last?.id == day.id
  }

  @ViewBuilder
  private func streakBadge() -> some View {
    HStack(spacing: 2) {
      Image(systemName: "flame.fill")
        .font(.system(size: 16))
        .foregroundStyle(.primary500)

      Text("\(weekly.consecutiveDays)일 연속 출석 중")
        .pretendardFont(.headingSmall)
        .foregroundStyle(.primary500)
    }
    .padding(.horizontal, 6)
    .padding(.vertical, 2)
    .background(
      RoundedRectangle(cornerRadius: 2)
        .fill(.secondary100)
    )
  }

  @ViewBuilder
  private func earnedPoints() -> some View {
    HStack(spacing: 2) {
      Text("+\(pointsEarned)P 획득")
        .pretendardFont(.labelMedium)
        .foregroundStyle(.gray500)

      ZStack {
        Circle().fill(.secondary300)
        Text("P")
          .pretendardFont(.bold11)
          .foregroundStyle(.secondary600)
      }
      .frame(width: 16, height: 16)
    }
  }

  @ViewBuilder
  private func footerBlock() -> some View {
    VStack(spacing: 10) {
      HStack(spacing: 4) {
        Image(systemName: "gift.fill")
          .font(.system(size: 20))
          .foregroundStyle(.primary500)

        Text("7일 연속 출석 시 +\(weekly.streakRewardPoints)P")
          .pretendardFont(.labelMedium)
          .foregroundStyle(.primary900)
      }
      .padding(.horizontal, 10)
      .padding(.vertical, 6)
      .background(
        RoundedRectangle(cornerRadius: 6)
          .fill(.beige200)
          .overlay(
            RoundedRectangle(cornerRadius: 6)
              .stroke(.primary50, lineWidth: 1)
          )
      )

      Text("실패해도 다음 주 월요일에 다시 도전해요")
        .pretendardFont(.bodySmall)
        .foregroundStyle(.gray300)
        .multilineTextAlignment(.center)
    }
  }
}

#Preview("연속 성공 중") {
  AttendanceSheetView(
    weekly: WeeklyAttendance(
      weekStartDate: "2026-07-20",
      consecutiveDays: 3,
      isStreakAchieved: false,
      days: [
        AttendanceDay(day: "월", date: "2026-07-20", status: .attended, points: 5),
        AttendanceDay(day: "화", date: "2026-07-21", status: .attended, points: 5),
        AttendanceDay(day: "수", date: "2026-07-22", status: .attended, points: 5),
        AttendanceDay(day: "목", date: "2026-07-23", status: .upcoming, points: 0),
        AttendanceDay(day: "금", date: "2026-07-24", status: .upcoming, points: 0),
        AttendanceDay(day: "토", date: "2026-07-25", status: .upcoming, points: 0),
        AttendanceDay(day: "일", date: "2026-07-26", status: .upcoming, points: 0),
      ],
      streakRewardPoints: 50
    ),
    pointsEarned: 5
  )
}

#Preview("결석 포함") {
  AttendanceSheetView(
    weekly: WeeklyAttendance(
      weekStartDate: "2026-07-20",
      consecutiveDays: 1,
      isStreakAchieved: false,
      days: [
        AttendanceDay(day: "월", date: "2026-07-20", status: .attended, points: 5),
        AttendanceDay(day: "화", date: "2026-07-21", status: .missed, points: 0),
        AttendanceDay(day: "수", date: "2026-07-22", status: .attended, points: 5),
        AttendanceDay(day: "목", date: "2026-07-23", status: .upcoming, points: 0),
        AttendanceDay(day: "금", date: "2026-07-24", status: .upcoming, points: 0),
        AttendanceDay(day: "토", date: "2026-07-25", status: .upcoming, points: 0),
        AttendanceDay(day: "일", date: "2026-07-26", status: .upcoming, points: 0),
      ],
      streakRewardPoints: 50
    ),
    pointsEarned: 5
  )
}
