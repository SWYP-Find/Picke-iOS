//
//  ClassSelectedBattleCard.swift
//  Class
//

import ClassDomainInterface
import PickeDesignKit
import PickeSharedUI
import SwiftUI

/// 설정과 공유 화면에서 선택한 배틀을 보여주는 카드.
struct ClassSelectedBattleCard: View {
  let battle: ClassBattleSummary

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      battleInfo()
      versusRow()
    }
    .padding(12)
    .frame(maxWidth: .infinity, alignment: .leading)
    .pickeCard(.beige50, border: .beige600, radius: 0)
  }
}

private extension ClassSelectedBattleCard {
  @ViewBuilder
  func battleInfo() -> some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
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
      }

      VStack(alignment: .leading, spacing: 4) {
        Text(battle.title)
          .pretendardFont(.headingSmall)
          .foregroundStyle(.gray500)
          .lineLimit(1)

        Text(battle.summary)
          .pretendardFont(.labelSmall)
          .foregroundStyle(.gray300)
          .lineLimit(1)
      }
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

      Text("VS")
        .pretendardFont(.bold8)
        .foregroundStyle(.gray900)
        .frame(width: 24, height: 24)
        .background(.secondary200, in: Circle())

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
    .frame(height: 58)
    .pickeCard(.beige300, border: .beige600)
  }
}
