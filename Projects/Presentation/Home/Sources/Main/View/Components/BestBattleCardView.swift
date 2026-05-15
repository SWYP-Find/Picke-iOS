//
//  BestBattleCardView.swift
//  Home
//
//  Created by Wonji Suh on 5/15/26.
//

import SwiftUI

import DesignSystem
import Entity

/// "Best 배틀" 랭킹 카드 (랭크 번호 + 페어 + 카테고리).
struct BestBattleCardView: View {
  let battle: BestBattle

  var body: some View {
    HStack(alignment: .top, spacing: 16) {
      Text("\(battle.rank)")
        .pretendardFont(family: .Bold, size: 28)
        .foregroundStyle(.primary500)
        .frame(width: 28, alignment: .leading)

      VStack(alignment: .leading, spacing: 6) {
        Text(battle.pair)
          .pretendardFont(family: .SemiBold, size: 11)
          .foregroundStyle(.primary500)
        Text(battle.title)
          .pretendardFont(family: .SemiBold, size: 14)
          .foregroundStyle(.neutral900)
          .lineLimit(2)
        HStack(spacing: 8) {
          ForEach(battle.tags) { tag in
            Text(tag.name)
              .pretendardFont(family: .Medium, size: 11)
              .foregroundStyle(.neutral300)
          }
          MetaLabelView(systemImage: "clock", text: "\(battle.durationMinutes)분")
          MetaLabelView(systemImage: "eye", text: "\(battle.viewCount.formatted())")
        }
      }
      Spacer(minLength: 0)
    }
    .padding(.vertical, 16)
    .padding(.horizontal, 12)
    .background(.beige50, in: RoundedRectangle(cornerRadius: 2))
    .overlay(
      RoundedRectangle(cornerRadius: 2).stroke(.beige600, lineWidth: 1)
    )
  }
}
