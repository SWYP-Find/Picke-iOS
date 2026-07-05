//
//  NewBattleCardView.swift
//  Home
//
//  Created by Wonji Suh on 5/15/26.
//

import SwiftUI

import DesignSystem
import Entity

import Kingfisher

/// "새로운 배틀" 리스트 카드 (.pen `Card/BattleListCard` 의 thumbnail 제외 구성).
struct NewBattleCardView: View {
  let battle: NewBattle

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      content
    }
    .padding(12)
    .background(.beige50, in: RoundedRectangle(cornerRadius: 2))
    .overlay(
      RoundedRectangle(cornerRadius: 2).stroke(.beige600, lineWidth: 1)
    )
  }
}

// MARK: - Sections

extension NewBattleCardView {
  @ViewBuilder
  private var content: some View {
    VStack(alignment: .leading, spacing: 16) {
      container
      versusRow
    }
  }

  @ViewBuilder
  private var container: some View {
    VStack(alignment: .leading, spacing: 12) {
      metaRow
      titleBlock
    }
  }

  @ViewBuilder
  private var metaRow: some View {
    HStack(spacing: 10) {
      if let tag = battle.tags.first {
        Text("#\(tag.name)")
          .pretendardFont(family: .SemiBold, size: 12)
          .foregroundStyle(.primary500)
          .padding(.horizontal, 6)
          .padding(.vertical, 2)
          .background(.beige600, in: RoundedRectangle(cornerRadius: 2))
      }
      Spacer()
      MetaLabelView(systemImage: "clock", text: "\(battle.durationMinutes)분")
      MetaLabelView(systemImage: "eye", text: "\(battle.viewCount.formatted())")
    }
  }

  @ViewBuilder
  private var titleBlock: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(battle.title)
        .pretendardCustomFont(textStyle: .headingSmall)
        .foregroundStyle(.neutral500)
        .kerning(-0.35)
        .lineLimit(2)
        .frame(maxWidth: .infinity, alignment: .leading)
      Text(battle.summary)
        .pretendardCustomFont(textStyle: .labelSmall)
        .foregroundStyle(.neutral200)
        .lineSpacing(12 * 0.4)
        .lineLimit(2)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
  }

  @ViewBuilder
  private var versusRow: some View {
    HStack(spacing: 8) {
      admissionButton(
        label: battle.optionATitle,
        sub: battle.philosopherA,
        imageURL: battle.philosopherAImageURL
      )
      vsBadge
      admissionButton(
        label: battle.optionBTitle,
        sub: battle.philosopherB,
        imageURL: battle.philosopherBImageURL
      )
    }
  }
}

// MARK: - Sub-components

extension NewBattleCardView {
  @ViewBuilder
  private func admissionButton(
    label: String,
    sub: String,
    imageURL: URL?
  ) -> some View {
    HStack(spacing: 4) {
      avatar(for: sub, imageURL: imageURL)
      VStack(alignment: .leading, spacing: 2) {
        Text(label)
          .pretendardCustomFont(textStyle: .headingSmall)
          .foregroundStyle(.neutral600)
          .kerning(-0.35)
        Text(sub)
          .pretendardCustomFont(textStyle: .labelSmall)
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

  @ViewBuilder
  private func avatar(
    for _: String,
    imageURL: URL?
  ) -> some View {
    // .pen `Avatar/Philosopher` 매핑: 베이지 40×40 원형 배경 + 가운데 16×28 일러스트
    ZStack {
      Circle()
        .fill(.beige600)
        .frame(width: 40, height: 40)
      if let imageURL {
        KFImage(imageURL)
          .placeholder { SkeletonView(cornerRadius: 20) }
          .resizable()
          .scaledToFit()
          .frame(width: 20, height: 38)
      }
    }
    .frame(width: 40, height: 40)
  }

  @ViewBuilder
  private var vsBadge: some View {
    // Figma(4037:4233 VS) 매핑: 24×24 secondary200(#F3E3C7) 원형 + Pretendard Bold 8 neutral900(#131212) 글자.
    Text("VS")
      .pretendardFont(family: .Bold, size: 8)
      .foregroundStyle(.neutral900)
      .frame(width: 24, height: 24)
      .background(.secondary200, in: Circle())
  }
}
