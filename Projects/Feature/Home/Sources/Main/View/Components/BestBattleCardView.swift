//
//  BestBattleCardView.swift
//  Home
//
//  Created by Picke on 5/15/26.
//

import HomeDomainInterface
import PickeDesignKit
import SwiftUI

/// "Best 배틀" 랭킹 행 (랭크 번호 + 페어 + 제목 + 태그/메타). Android `BestBattleRankItem` 시안.
struct BestBattleCardView: View {
  let battle: BestBattle

  var body: some View {
    HStack(alignment: .center, spacing: 16) {
      rankText
      infoSection()
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .accessibilityElement(children: .combine)
    .accessibilityAddTraits(.isButton)
  }
}

extension BestBattleCardView {
  private var rankText: some View {
    Text("\(battle.rank)")
      .pretendardFont(.semiBold24)
      .foregroundStyle(battle.rank == 1 ? .primary500 : .gray100)
      .frame(width: 16, alignment: .center)
  }

  @ViewBuilder
  private func infoSection() -> some View {
    VStack(alignment: .leading, spacing: 12) {
      titleSection()
      metaSection()
    }
  }

  @ViewBuilder
  private func titleSection() -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(battle.pair)
        .pickeBadge(.filled, size: .tag)
      Text(battle.title)
        .pretendardFont(.headingSmall, lineHeightMultiple: 1.3)
        .foregroundStyle(.cardBaseTextTitle)
        .lineLimit(1)
        .truncationMode(.tail)
    }
  }

  @ViewBuilder
  private func metaSection() -> some View {
    HStack(spacing: 0) {
      HStack(spacing: 4) {
        ForEach(battle.tags) { tag in
          Text("#\(tag.name)")
            .pretendardFont(.labelSmall, lineHeightMultiple: 1.4)
            .foregroundStyle(.cardBaseTextDecription)
        }
      }
      Spacer(minLength: 8)
      HStack(spacing: 6) {
        metaLabel(
          systemImage: "clock",
          text: "\(battle.durationMinutes)분"
        )
        metaLabel(
          systemImage: "eye",
          text: "\(battle.viewCount.formatted())"
        )
      }
    }
  }

  @ViewBuilder
  private func metaLabel(
    systemImage: String,
    text: String
  ) -> some View {
    HStack(spacing: 2) {
      Image(systemName: systemImage)
        .resizable()
        .scaledToFit()
        .frame(width: 16, height: 16)
      Text(text)
        .pretendardFont(.labelSmall, lineHeightMultiple: 1.4)
    }
    .foregroundStyle(.cardBaseTextDecription)
  }
}
