//
//  ClassBattleListCard.swift
//  Class
//

import ClassDomainInterface
import PickeDesignKit
import PickeSharedUI
import SwiftUI

/// 추천 배틀 목록 카드. 선택 시 primary500 테두리 + 체크박스가 채워진다.
struct ClassBattleListCard: View {
  let battle: ClassBattleSummary
  let isSelected: Bool
  let onPreview: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      VStack(alignment: .leading, spacing: 12) {
        metaRow()
        titleSection()
      }
      versusRow()
    }
    .padding(12)
    .frame(maxWidth: .infinity, alignment: .leading)
    .pickeCard(.beige50, border: isSelected ? .primary500 : .beige600)
    .contentShape(Rectangle())
  }
}

private extension ClassBattleListCard {
  @ViewBuilder
  func metaRow() -> some View {
    HStack(spacing: 10) {
      Text("#\(battle.category.title)")
        .pickeBadge(.filled, size: .tag)

      Spacer(minLength: 0)

      HStack(spacing: 2) {
        Image(systemName: "clock")
          .pretendardFont(.labelXSmall)
        Text("\(battle.durationMinutes)분")
          .pretendardFont(.labelSmall)
      }
      .foregroundStyle(.gray300)

      previewButton

      Image(systemName: "checkmark")
        .pickeCheckbox(isChecked: isSelected)
    }
  }

  var previewButton: some View {
    Button(action: onPreview) {
      HStack(spacing: 2) {
        Image(systemName: "play.fill")
          .pretendardFont(.labelXSmall)
        Text("미리듣기")
          .pretendardFont(.semiBold12)
      }
      .foregroundStyle(.gray300)
    }
    .buttonStyle(.plain)
    .disabled(true)
    .accessibilityHint("미리듣기는 준비 중입니다")
  }

  @ViewBuilder
  func titleSection() -> some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(battle.title)
        .pretendardFont(.headingSmall)
        .foregroundStyle(.gray500)
        .lineLimit(1)

      Text(battle.summary)
        .pretendardFont(.labelSmall)
        .foregroundStyle(.gray200)
        .lineLimit(1)
    }
  }

  @ViewBuilder
  func versusRow() -> some View {
    HStack(spacing: 8) {
      optionSide(
        title: battle.optionATitle,
        philosopher: battle.philosopherA,
        imageURL: battle.philosopherAImageURL
      )

      versusBadge

      optionSide(
        title: battle.optionBTitle,
        philosopher: battle.philosopherB,
        imageURL: battle.philosopherBImageURL
      )
    }
  }

  @ViewBuilder
  func optionSide(
    title: String,
    philosopher: String,
    imageURL: URL?
  ) -> some View {
    HStack(spacing: 4) {
      PickeAvatarView(
        imageURL: imageURL?.absoluteString,
        fallback: philosopher,
        size: 40
      )

      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .pretendardFont(.semiBold11)
          .foregroundStyle(.gray500)
        Text(philosopher)
          .pretendardFont(.regular10)
          .foregroundStyle(.gray300)
      }
      .lineLimit(1)

      Spacer(minLength: 0)
    }
    .padding(8)
    .frame(maxWidth: .infinity)
    .pickeCard(.beige300, border: .beige600)
  }

  var versusBadge: some View {
    Text("VS")
      .pretendardFont(.bold8)
      .foregroundStyle(.gray900)
      .frame(width: 24, height: 24)
      .background(.secondary200, in: Circle())
  }
}
