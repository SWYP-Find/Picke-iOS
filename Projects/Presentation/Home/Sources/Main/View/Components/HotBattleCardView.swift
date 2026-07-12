//
//  HotBattleCardView.swift
//  Home
//
//  Created by Wonji Suh on 5/15/26.
//

import SwiftUI

import PickeDesignKit
import Entity

import Kingfisher

/// "지금 뜨는 배틀" 가로 스크롤 카드 (220 wide).
struct HotBattleCardView: View {
  let battle: HotBattle

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      thumbnail
      VStack(alignment: .leading, spacing: 6) {
        if let tag = battle.tags.first {
          Text("#\(tag.name)")
            .pretendardFont(.medium11)
            .foregroundStyle(.primary500)
        }
        Text(battle.title)
          .pretendardFont(.headingSmall)
          .foregroundStyle(.neutral900)
          // 제목 1줄이어도 2줄 높이를 확보해 카드 높이를 통일. 2줄 초과는 말줄임(...) 처리.
          .lineLimit(2, reservesSpace: true)
          .truncationMode(.tail)
        HStack(spacing: 8) {
          MetaLabelView(systemImage: "clock", text: "\(battle.durationMinutes)분")
          MetaLabelView(systemImage: "eye", text: "\(battle.viewCount.formatted())")
        }
      }
    }
    .padding(12)
    .frame(width: 220, alignment: .leading)
    .roundedBackground(.beige50)
    .overlay(
      RoundedRectangle(cornerRadius: .radiusDefault).stroke(.beige600, lineWidth: 1)
    )
  }

  @ViewBuilder
  private var thumbnail: some View {
    // QA-43: Figma node 3888-3736 기준 — height 140, border 4pt(.borderBeigeSelected), radius 2.
    Group {
      if let url = battle.thumbnailURL {
        KFImage(url)
          .placeholder { SkeletonView() }
          .resizable()
          .scaledToFill()
      } else {
        Rectangle()
          .fill(.beige500)
      }
    }
    .frame(width: 196, height: 140)
    .clipShape(RoundedRectangle(cornerRadius: .radiusDefault))
    .overlay(
      RoundedRectangle(cornerRadius: .radiusDefault).stroke(.borderBeigeSelected, lineWidth: 4)
    )
  }
}
