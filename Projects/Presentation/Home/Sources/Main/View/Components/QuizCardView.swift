//
//  QuizCardView.swift
//  Home
//
//  Created by Wonji Suh on 5/15/26.
//

import SwiftUI

import DesignSystem
import Entity

/// "오늘의 Pické — 퀴즈" 카드.
struct QuizCardView: View {
  let question: QuizQuestion

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      header
      titleBlock
      options
    }
    .padding(.vertical, 20)
    .padding(.horizontal, 16)
    .background(.beige400, in: RoundedRectangle(cornerRadius: 2))
    .overlay(
      RoundedRectangle(cornerRadius: 2).stroke(.beige700, lineWidth: 1)
    )
  }

  private var header: some View {
    HStack {
      TagBadgeView(text: "퀴즈")
      Spacer()
      Text("\(question.participantCount.formatted())명 참여")
        .pretendardFont(family: .Medium, size: 11)
        .foregroundStyle(.neutral300)
    }
  }

  private var titleBlock: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(question.title)
        .pretendardFont(family: .SemiBold, size: 15)
        .foregroundStyle(.neutral900)
        .kerning(-0.375)
      Text(question.subtitle)
        .pretendardFont(family: .Medium, size: 12)
        .foregroundStyle(.neutral200)
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
    }
  }

  private var options: some View {
    HStack(spacing: 8) {
      option(label: question.optionA)
      option(label: question.optionB)
    }
  }

  private func option(label: String) -> some View {
    VStack(spacing: 2) {
      Text(label)
        .pretendardFont(family: .SemiBold, size: 13)
        .foregroundStyle(.neutral900)
      Text("explanation")
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
