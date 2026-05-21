//
//  HotBattleCardView.swift
//  Home
//
//  Created by Wonji Suh on 5/15/26.
//

import SwiftUI

import DesignSystem
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
            .pretendardFont(family: .Medium, size: 11)
            .foregroundStyle(.primary500)
        }
        Text(battle.title)
          .pretendardFont(family: .SemiBold, size: 14)
          .foregroundStyle(.neutral900)
          .lineLimit(2)
        HStack(spacing: 8) {
          MetaLabelView(systemImage: "clock", text: "\(battle.durationMinutes)분")
          MetaLabelView(systemImage: "eye", text: "\(battle.viewCount.formatted())")
        }
      }
    }
    .padding(12)
    .frame(width: 220, alignment: .leading)
    .background(.beige50, in: RoundedRectangle(cornerRadius: 2))
    .overlay(
      RoundedRectangle(cornerRadius: 2).stroke(.beige600, lineWidth: 1)
    )
  }

  @ViewBuilder
  private var thumbnail: some View {
    if let url = battle.thumbnailURL {
      KFImage(url)
        .placeholder { SkeletonView() }
        .resizable()
        .scaledToFill()
        .frame(width: 196, height: 124)
        .clipShape(RoundedRectangle(cornerRadius: 2))
    } else {
      RoundedRectangle(cornerRadius: 2)
        .fill(.beige500)
        .frame(width: 196, height: 124)
    }
  }
}
