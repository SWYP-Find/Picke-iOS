//
//  QuizCardView.swift
//  Home
//
//  Created by Wonji Suh on 5/15/26.
//
//  Pencil .pen `Card/Quiz` — 단일 상태 (Property variant 없음).
//

import SwiftUI

import DesignSystem
import Entity

/// "오늘의 Pické — 퀴즈" 카드. (선택/결과 상태 분리 없음 — .pen 디자인 단일)
struct QuizCardView: View {
  let question: QuizQuestion

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      header()
      titleBlock()
      options()
    }
    .padding(.vertical, 20)
    .padding(.horizontal, 16)
    .background(.beige400, in: RoundedRectangle(cornerRadius: 2))
    .overlay(
      RoundedRectangle(cornerRadius: 2).stroke(.beige700, lineWidth: 1)
    )
  }

  @ViewBuilder
  private func header() -> some View {
    HStack {
      TagBadgeView(text: "퀴즈")
      Spacer()
      Text("\(question.participantCount.formatted())명 참여")
        .pretendardFont(family: .Medium, size: 11)
        .foregroundStyle(.neutral300)
    }
  }

  @ViewBuilder
  private func titleBlock() -> some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(question.title)
        .pretendardFont(family: .SemiBold, size: 15)
        .foregroundStyle(.neutral900)
        .kerning(-0.375)
      Text(question.summary)
        .pretendardFont(family: .Medium, size: 12)
        .foregroundStyle(.neutral200)
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
    }
  }

  @ViewBuilder
  private func options() -> some View {
    HStack(spacing: 8) {
      option(label: question.itemA, desc: question.itemADesc)
      option(label: question.itemB, desc: question.itemBDesc)
    }
  }

  @ViewBuilder
  private func option(label: String, desc: String) -> some View {
    VStack(spacing: 2) {
      Text(label)
        .pretendardFont(family: .SemiBold, size: 13)
        .foregroundStyle(.neutral900)
      Text(desc)
        .pretendardFont(family: .Medium, size: 11)
        .foregroundStyle(.neutral300)
    }
    .frame(maxWidth: .infinity)
    .padding(12)
    .background(.beige50, in: RoundedRectangle(cornerRadius: 2))
    .overlay(
      RoundedRectangle(cornerRadius: 2).stroke(.beige500, lineWidth: 1)
    )
  }
}
