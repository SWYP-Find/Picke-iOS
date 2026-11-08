//
//  HotBattleCardView.swift
//  Home
//
//  Created by Picke on 5/15/26.
//

import HomeDomainInterface
import PickeDesignKit
import PickeSharedUI
import SwiftUI

/// "지금 뜨는 배틀" 가로 스크롤 카드 — Android `TrendingBattleCard` 시안(폭 220).
struct HotBattleCardView: View {
  let battle: HotBattle

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      thumbnail
      tagBadge
        .padding(.top, 12)
      titleText
        .padding(.top, 8)
      metaRow()
        .padding(.top, 12)
    }
    .padding(12)
    .frame(width: 220, alignment: .leading)
    .pickeCard(
      .surfaceBeigeDefault,
      border: .borderBeigeDefault,
      insideBorder: true
    )
  }
}

extension HotBattleCardView {
  /// 1.2 비율 썸네일 — 바깥 radius 4 + 안쪽 테두리 4(borderBeigeSelected), 이미지가 없으면 배경색만.
  private var thumbnail: some View {
    Color.bgBeige
      .aspectRatio(1.2, contentMode: .fit)
      .overlay {
        if let url = battle.thumbnailURL {
          PickeRemoteImage(url: url) {
            SkeletonView(
              .rect,
              base: .surfaceBeigeStrong,
              highlight: .surfaceBeigeDefault
            )
          }
        }
      }
      .clipShape(RoundedRectangle(cornerRadius: 4))
      .roundedBorder(
        .borderBeigeSelected,
        lineWidth: 4,
        radius: 4,
        insideBorder: true
      )
  }

  private var tagBadge: some View {
    Text("#\(battle.tags.first?.name ?? "이슈")")
      .pretendardFont(.labelXSmall)
      .foregroundStyle(.primary500)
      .padding(.horizontal, 6)
      .padding(.vertical, 2)
      .roundedBackground(.borderBeigeDefault)
  }

  private var titleText: some View {
    Text(battle.title)
      .pretendardFont(.headingSmall)
      .foregroundStyle(.textDefault)
      .lineLimit(1)
      .truncationMode(.tail)
  }

  @ViewBuilder
  private func metaRow() -> some View {
    HStack(spacing: 8) {
      MetaLabelView(
        asset: .clock,
        text: "\(battle.durationMinutes)분"
      )
      MetaLabelView(
        asset: .eye,
        text: "\(battle.viewCount.formatted())"
      )
    }
  }
}
