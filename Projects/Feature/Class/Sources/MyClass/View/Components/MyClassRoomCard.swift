//
//  MyClassRoomCard.swift
//  Class
//

import ClassDomainInterface
import PickeDesignKit
import SwiftUI

/// 내 클래스 목록 카드 (Figma 12178:8263 `Card/BattleListCard`).
struct MyClassRoomCard: View {
  let room: ClassRoom

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      VStack(alignment: .leading, spacing: 12) {
        badgeRow()
        titleSection()
      }

      footer()
    }
    .padding(12)
    .frame(maxWidth: .infinity, alignment: .leading)
    .pickeCard(.beige50, border: .beige600)
    .contentShape(Rectangle())
  }
}

private extension MyClassRoomCard {
  @ViewBuilder
  func badgeRow() -> some View {
    HStack(alignment: .top, spacing: 10) {
      statusBadge

      Spacer(minLength: 0)

      Image(systemName: "ellipsis")
        .font(.pretendardFontFamily(family: .Bold, size: 14))
        .foregroundStyle(.gray900)
        .frame(width: 24, height: 24)
    }
  }

  @ViewBuilder
  var statusBadge: some View {
    switch room.status {
    case .open:
      Text("진행 중")
        .pickeBadge(.filled, size: .tag)
    case .closed:
      Text("종료")
        .pretendardFont(.semiBold12)
        .foregroundStyle(.gray300)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .roundedBackground(.gray50)
    }
  }

  @ViewBuilder
  func titleSection() -> some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(room.name)
        .pretendardFont(.headingMedium)
        .foregroundStyle(.gray500)
        .lineLimit(1)

      Text(room.battle.title)
        .pretendardFont(.regular13)
        .foregroundStyle(.gray300)
        .lineLimit(1)
    }
  }

  @ViewBuilder
  func footer() -> some View {
    HStack(spacing: 6) {
      metaItem(
        systemName: "person",
        text: "멤버 \(room.memberCount)명"
      )

      if let deadlineText {
        Circle()
          .fill(.gray300)
          .frame(width: 2, height: 2)

        metaItem(
          systemName: "calendar",
          text: deadlineText
        )
      }

      Spacer(minLength: 0)

      viewLabel
    }
    .padding(.top, 12)
    .overlay(alignment: .top) {
      Rectangle()
        .fill(.beige600)
        .frame(height: 1)
    }
  }

  @ViewBuilder
  func metaItem(
    systemName: String,
    text: String
  ) -> some View {
    HStack(spacing: 2) {
      Image(systemName: systemName)
        .font(.pretendardFontFamily(family: .Regular, size: 10))
        .frame(width: 12, height: 12)
      Text(text)
        .pretendardFont(.bodySmall)
        .lineLimit(1)
    }
    .foregroundStyle(.gray300)
  }

  var viewLabel: some View {
    HStack(spacing: 4) {
      Text("보기")
        .pretendardFont(family: .Bold, size: 12)
      Image(systemName: "chevron.right")
        .font(.pretendardFontFamily(family: .Bold, size: 9))
        .frame(width: 12, height: 12)
    }
    .foregroundStyle(.primary500)
  }

  /// 마감일을 끈 클래스(`.distantFuture`)는 표시하지 않는다.
  var deadlineText: String? {
    guard room.deadline != .distantFuture else { return nil }
    return "\(Self.deadlineFormatter.string(from: room.deadline))까지"
  }

  static let deadlineFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "ko_KR")
    formatter.dateFormat = "yyyy. MM. dd. EEEE HH:mm"
    return formatter
  }()
}
