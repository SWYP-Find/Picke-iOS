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
    Text("#\(battle.tags.first?.name ?? "이슈")")
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
      opinionBox(
        opinion: battle.optionATitle,
        name: battle.philosopherA,
        imageURL: battle.philosopherAImageURL
      )
      vsBadge
      opinionBox(
        opinion: battle.optionBTitle,
        name: battle.philosopherB,
        imageURL: battle.philosopherBImageURL
      )
    }
  }
}

// MARK: - Sub-components

extension NewBattleCardView {
  /// Android `BattleOpinionBox` — 프로필 40 + 의견·이름 한 줄씩.
  @ViewBuilder
  private func opinionBox(
    opinion: String,
    name: String,
    imageURL: URL?
  ) -> some View {
    HStack(spacing: 4) {
      profileImage(imageURL)
      VStack(alignment: .leading, spacing: 2) {
        Text(opinion)
          .pretendardFont(.labelSmall)
          .foregroundStyle(.textSubtle)
          .lineLimit(1)
          .truncationMode(.tail)
        Text(name)
          .pretendardFont(.labelXSmall)
          .foregroundStyle(.textMuted)
          .lineLimit(1)
          .truncationMode(.tail)
      }
      Spacer(minLength: 0)
    }
    .padding(8)
    .frame(maxWidth: .infinity)
    .pickeCard(
      .surfaceBeigeSubtle,
      border: .borderBeigeDisabled,
      insideBorder: true
    )
  }

  /// Android `ProfileImage`(CHARACTER) — 40 원 배경 + 가운데 2/3 크기 이미지(fit).
  @ViewBuilder
  private func profileImage(_ imageURL: URL?) -> some View {
    ZStack {
      Circle()
        .fill(.borderBeigeDefault)
      if let imageURL {
        PickeRemoteImage(url: imageURL) {
          Color.clear
        }
        .content(.fit)
        .frame(width: 40 * 2 / 3, height: 40 * 2 / 3)
      }
    }
    .frame(width: 40, height: 40)
  }

  /// Android VS — 40 영역 안 28 원(secondary200) + 10 SemiBold "VS".
  private var vsBadge: some View {
    Text("VS")
      .pretendardFont(.labelXSmall)
      .foregroundStyle(.textDefault)
      .frame(width: 28, height: 28)
      .background(.secondary200, in: Circle())
      .frame(width: 40, height: 40)
  }
}
