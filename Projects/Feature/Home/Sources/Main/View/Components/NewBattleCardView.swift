//
//  NewBattleCardView.swift
//  Home
//
//  Created by Picke on 5/15/26.
//

import HomeDomainInterface
import PickeDesignKit
import PickeSharedUI
import SwiftUI

/// "새로운 배틀" 리스트 카드 — Android `NewBattleCard` 시안.
struct NewBattleCardView: View {
  let battle: NewBattle

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      metaRow()
      titleText
        .padding(.top, 12)
      summaryText
        .padding(.top, 6)
      versusRow()
        .padding(.top, 8)
    }
    .padding(12)
    .pickeCard(
      .surfaceBeigeDefault,
      border: .borderBeigeDefault,
      insideBorder: true
    )
  }
}

// MARK: - Sections

extension NewBattleCardView {
  @ViewBuilder
  private func metaRow() -> some View {
    HStack(spacing: 0) {
      tagBadge
      Spacer(minLength: 0)
      HStack(spacing: 8) {
        MetaLabelView(
          asset: .clock,
          text: "\(battle.durationMinutes)분",
          spacing: 4
        )
        MetaLabelView(
          asset: .eye,
          text: "\(battle.viewCount.formatted())",
          spacing: 4
        )
      }
    }
  }

  private var tagBadge: some View {
    Text(battle.tagLabel)
      .pretendardFont(.labelSmall)
      .foregroundStyle(.primary500)
      .padding(.horizontal, 6)
      .padding(.vertical, 2)
      .roundedBackground(.borderBeigeDefault)
  }

  private var titleText: some View {
    Text(battle.title)
      .pretendardFont(.headingSmall, lineSpacingMultiple: 1.4)
      .foregroundStyle(.textDefault)
      .frame(maxWidth: .infinity, alignment: .leading)
  }

  private var summaryText: some View {
    Text(battle.summary)
      .pretendardFont(.labelSmall, lineSpacingMultiple: 1.4)
      .foregroundStyle(.gray400)
      .lineLimit(2)
      .truncationMode(.tail)
      .frame(maxWidth: .infinity, alignment: .leading)
  }

  @ViewBuilder
  private func versusRow() -> some View {
    HStack(spacing: 2) {
      BattleOpinionBox(
        opinion: battle.optionATitle,
        name: battle.philosopherA,
        imageURL: battle.philosopherAImageURL
      )
      BattleVersusBadge()
      BattleOpinionBox(
        opinion: battle.optionBTitle,
        name: battle.philosopherB,
        imageURL: battle.philosopherBImageURL
      )
    }
  }
}
