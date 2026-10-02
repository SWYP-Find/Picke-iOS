//
//  ClassSelectedBattleCard.swift
//  Class
//

import ClassDomainInterface
import PickeCoreUtility
import PickeDesignKit
import PickeSharedUI
import SwiftUI

/// 클래스 설정 / 공유 화면의 "선택한 배틀" 카드.
struct ClassSelectedBattleCard: View {
  let battle: ClassBattleSummary

  var body: some View {
    HStack(alignment: .top, spacing: 8) {
      PickeRemoteImage(url: battle.thumbnailURL) { Color.beige600 }
        .frame(width: 76, height: 106)
        .clipShape(RoundedRectangle(cornerRadius: .radiusDefault))

      VStack(alignment: .leading, spacing: 24) {
        VStack(alignment: .leading, spacing: 8) {
          HStack(spacing: 6) {
            Text("#\(battle.category.title)")
              .pickeBadge(.filled, size: .tag)
            Text(battle.title)
              .pretendardFont(.headingSmall)
              .foregroundStyle(.gray500)
              .lineLimit(1)
          }

          Text(battle.summary)
            .pretendardFont(.regular13)
            .foregroundStyle(.gray400)
            .lineLimit(2)
            .padding(.horizontal, 2)
        }

        HStack(spacing: 6) {
          Spacer(minLength: 0)
          metaLabel(
            systemImage: "clock",
            text: "\(battle.durationMinutes)분"
          )
          metaLabel(
            systemImage: "eye",
            text: battle.viewCount.decimalFormatted
          )
        }
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .frame(maxWidth: .infinity, alignment: .leading)
    .pickeCard(.beige50, border: .beige600, radius: 0)
  }
}

private extension ClassSelectedBattleCard {
  @ViewBuilder
  func metaLabel(
    systemImage: String,
    text: String
  ) -> some View {
    HStack(spacing: 2) {
      Image(systemName: systemImage)
        .pretendardFont(.labelXSmall)
      Text(text)
        .pretendardFont(.labelSmall)
    }
    .foregroundStyle(.gray300)
  }
}
