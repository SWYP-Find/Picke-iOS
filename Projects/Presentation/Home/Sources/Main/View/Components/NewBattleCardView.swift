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
    content
      .padding(12)
      .background(.beige50, in: RoundedRectangle(cornerRadius: 2))
      .overlay(
        RoundedRectangle(cornerRadius: 2).stroke(.beige600, lineWidth: 1)
      )
  }
}

// MARK: - Sections

extension NewBattleCardView {
  private var content: some View {
    VStack(alignment: .leading, spacing: 12) {
      container
      versusRow
    }
  }

  private var container: some View {
    VStack(alignment: .leading, spacing: 12) {
      metaRow
      titleBlock
    }
  }

  private var metaRow: some View {
    HStack(spacing: 10) {
      if let tag = battle.tags.first {
        Text(tag.name)
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

  private var titleBlock: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(battle.title)
        .pretendardFont(family: .SemiBold, size: 14)
        .foregroundStyle(.neutral500)
        .kerning(-0.35)
        .lineLimit(2)
        .frame(maxWidth: .infinity, alignment: .leading)
      Text(battle.summary)
        .pretendardFont(family: .Medium, size: 12)
        .foregroundStyle(.neutral200)
        .lineSpacing(12 * 0.4)
        .lineLimit(2)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
  }

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
  private func admissionButton(
    label: String,
    sub: String,
    imageURL: URL?
  ) -> some View {
    HStack(spacing: 4) {
      avatar(for: sub, imageURL: imageURL)
      VStack(alignment: .leading, spacing: 2) {
        Text(label)
          .pretendardFont(family: .SemiBold, size: 14)
          .foregroundStyle(.neutral600)
          .kerning(-0.35)
        Text(sub)
          .pretendardFont(family: .Medium, size: 12)
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
  private func avatar(for philosopherName: String, imageURL: URL?) -> some View {
    if let imageURL {
      KFImage(imageURL)
        .resizable()
        .scaledToFill()
        .frame(width: 40, height: 40)
        .clipShape(Circle())
    } else if let asset = PhilosopherAvatar(rawValue: philosopherName)?.imageAsset {
      Image(asset: asset)
        .resizable()
        .scaledToFit()
        .frame(width: 40, height: 40)
        .background(.beige600, in: Circle())
    } else {
      Circle()
        .fill(.beige600)
        .frame(width: 40, height: 40)
    }
  }

  private var vsBadge: some View {
    Text("VS")
      .pretendardFont(family: .Bold, size: 8)
      .foregroundStyle(.neutral800)
      .frame(width: 24, height: 24)
      .background(.secondary200, in: Circle())
      .overlay(Circle().stroke(.beige50, lineWidth: 1.5))
  }
}

private extension PhilosopherAvatar {
  var imageAsset: ImageAsset {
    switch self {
    case .plato: .avatarPlato
    case .sartre: .avatarSartre
    case .sunja: .avatarSunja
    }
  }
}
