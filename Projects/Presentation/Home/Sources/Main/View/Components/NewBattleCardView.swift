//
//  NewBattleCardView.swift
//  Home
//
//  Created by Wonji Suh on 5/15/26.
//

import SwiftUI

import DesignSystem
import Entity

/// "새로운 배틀" 리스트 카드 (제목 + VS 아바타 두 개).
struct NewBattleCardView: View {
  let battle: NewBattle

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      headerRow
      titleBlock
      versusRow
    }
    .padding(12)
    .background(.beige50, in: RoundedRectangle(cornerRadius: 2))
    .overlay(
      RoundedRectangle(cornerRadius: 2).stroke(.beige600, lineWidth: 1)
    )
  }

  private var headerRow: some View {
    HStack {
      Text(battle.tag)
        .pretendardFont(family: .Medium, size: 11)
        .foregroundStyle(.primary500)
      Spacer()
      MetaLabelView(systemImage: "clock", text: "\(battle.durationMinutes)분")
      MetaLabelView(systemImage: "eye", text: "\(battle.viewCount.formatted())")
    }
  }

  private var titleBlock: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(battle.title)
        .pretendardFont(family: .SemiBold, size: 14)
        .foregroundStyle(.neutral900)
        .lineLimit(2)
      Text(battle.subtitle)
        .pretendardFont(family: .Medium, size: 12)
        .foregroundStyle(.neutral300)
        .lineLimit(2)
    }
  }

  private var versusRow: some View {
    HStack(spacing: 8) {
      NewBattleAvatarPill(label: battle.avatarLabelA, sub: battle.avatarSubA)
      Text("VS")
        .pretendardFont(family: .SemiBold, size: 11)
        .foregroundStyle(.neutral300)
      NewBattleAvatarPill(label: battle.avatarLabelB, sub: battle.avatarSubB)
    }
  }
}

/// 새로운 배틀 카드 안의 발화자 아바타 (원형 placeholder + 라벨).
struct NewBattleAvatarPill: View {
  let label: String
  let sub: String

  var body: some View {
    HStack(spacing: 8) {
      Circle()
        .fill(.beige500)
        .frame(width: 28, height: 28)
      VStack(alignment: .leading, spacing: 0) {
        Text(label)
          .pretendardFont(family: .SemiBold, size: 12)
          .foregroundStyle(.neutral900)
        Text(sub)
          .pretendardFont(family: .Medium, size: 10)
          .foregroundStyle(.neutral300)
      }
      Spacer(minLength: 0)
    }
    .padding(8)
    .frame(maxWidth: .infinity)
    .background(.beige300, in: RoundedRectangle(cornerRadius: 2))
    .overlay(
      RoundedRectangle(cornerRadius: 2).stroke(.beige600, lineWidth: 1)
    )
  }
}
