//
//  BestBattleCardView.swift
//  Home
//
//  Created by Wonji Suh on 5/15/26.
//

import SwiftUI

import PickeDesignKit
import Entity

/// "Best 배틀" 랭킹 카드 (랭크 번호 + 페어 + 카테고리).
struct BestBattleCardView: View {
  let battle: BestBattle

  var body: some View {
    HStack(alignment: .center, spacing: 16) {
      Text("\(battle.rank)")
        .pretendardFont(.bold28)
        .foregroundStyle(battle.rank == 1 ? .primary500 : .neutral300)
        .frame(width: 28, alignment: .center) // QA-41: 순위 숫자(1,2,3) 중앙정렬

      VStack(alignment: .leading, spacing: 8) {
        Text(battle.pair)
          .pretendardFont(.semiBold11)
          .foregroundStyle(.primary500)
          .padding(.horizontal, 8)
          .padding(.vertical, 4)
          .roundedBackground(.beige600)

        Text(battle.title)
          .pretendardFont(.headingSmall)
          .foregroundStyle(.neutral900)
          .lineLimit(2)
          .truncationMode(.tail)
          .frame(maxWidth: .infinity, alignment: .leading)

        HStack(spacing: 8) {
          ForEach(battle.tags) { tag in
            Text("#\(tag.name)")
              .pretendardFont(.medium11)
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
