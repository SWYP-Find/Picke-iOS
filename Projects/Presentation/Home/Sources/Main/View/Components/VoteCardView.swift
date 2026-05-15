//
//  VoteCardView.swift
//  Home
//
//  Created by Wonji Suh on 5/15/26.
//
//  Pencil .pen `wZ4Yt` (Card/Vote) 기준으로 1:1 매핑.
//

import SwiftUI

import DesignSystem
import Entity

/// "오늘의 Pické — 투표" 카드.
struct VoteCardView: View {
  let question: VoteQuestion

  private let columns = [
    GridItem(.flexible(), spacing: 8),
    GridItem(.flexible(), spacing: 8),
  ]

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      header
      heading
      grid
    }
    .padding(.vertical, 20)
    .padding(.horizontal, 16)
    .background(.beige50, in: RoundedRectangle(cornerRadius: 2))
    .overlay(
      RoundedRectangle(cornerRadius: 2).stroke(.beige700, lineWidth: 1)
    )
  }

  private var header: some View {
    HStack {
      Text("투표")
        .pretendardFont(family: .SemiBold, size: 14)
        .kerning(-0.35)
        .foregroundStyle(.primary500)
        .frame(width: 35, height: 21)
        .background(.beige600, in: RoundedRectangle(cornerRadius: 2))

      Spacer()

      Text("\(question.participantCount.formatted())명 참여")
        .pretendardFont(family: .Medium, size: 11)
        .foregroundStyle(.neutral300)
    }
  }

  private var heading: some View {
    VStack(spacing: 6) {
      HStack(spacing: 4) {
        Text(question.titlePrefix)
          .pretendardFont(family: .SemiBold, size: 15)
          .kerning(-0.375)
          .foregroundStyle(.neutral900)

        RoundedRectangle(cornerRadius: 2)
          .fill(.beige200)
          .frame(width: 52, height: 24)
          .overlay(
            RoundedRectangle(cornerRadius: 2)
              .stroke(.beige700, lineWidth: 1)
          )

        Text(question.titleSuffix)
          .pretendardFont(family: .SemiBold, size: 15)
          .kerning(-0.375)
          .foregroundStyle(.neutral900)
      }

      Text(question.summary)
        .pretendardFont(family: .Medium, size: 12)
        .foregroundStyle(.neutral200)
    }
    .frame(maxWidth: .infinity)
  }

  private var grid: some View {
    LazyVGrid(columns: columns, spacing: 8) {
      ForEach(Array(question.options.enumerated()), id: \.offset) { idx, option in
        optionButton(index: idx + 1, label: option.title)
      }
    }
  }

  private func optionButton(index: Int, label: String) -> some View {
    HStack(spacing: 2) {
      Text("\(index).")
        .pretendardFont(family: .SemiBold, size: 10)
        .foregroundStyle(.secondary900)
      Text(label)
        .pretendardFont(family: .SemiBold, size: 13)
        .foregroundStyle(.neutral900)
    }
    .frame(maxWidth: .infinity, minHeight: 44)
    .background(.beige300, in: RoundedRectangle(cornerRadius: 2))
    .overlay(
      RoundedRectangle(cornerRadius: 2).stroke(.beige600, lineWidth: 1)
    )
  }
}
