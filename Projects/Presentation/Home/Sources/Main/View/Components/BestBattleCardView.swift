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
        .foregroundStyle(battle.rank == 1 ? .primary500 : .neutral300)
        .frame(width: 28, alignment: .leading)

      VStack(alignment: .leading, spacing: 8) {
        Text(battle.pair)
          .pretendardFont(family: .SemiBold, size: 11)
          .foregroundStyle(.primary500)
          .padding(.horizontal, 8)
          .padding(.vertical, 4)
          .background(.beige600, in: RoundedRectangle(cornerRadius: 2))

        Text(battle.title)
          .pretendardFont(family: .SemiBold, size: 14)
          .foregroundStyle(.neutral900)
          .lineLimit(2)
          .truncationMode(.tail)
          .frame(maxWidth: .infinity, alignment: .leading)

        HStack(spacing: 8) {
          ForEach(battle.tags) { tag in
            Text("#\(tag.name)")
              .pretendardFont(family: .Medium, size: 11)
              .foregroundStyle(.neutral300)
          }
          Spacer(minLength: 8)
          MetaLabelView(systemImage: "clock", text: "\(battle.durationMinutes)분")
          MetaLabelView(systemImage: "eye", text: "\(battle.viewCount.formatted())")
        }
      }
    }
    .padding(.vertical, 16)
  }
}
