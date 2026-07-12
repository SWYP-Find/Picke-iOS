//
//  QuizCardView.swift
//  Home
//
//  Created by Wonji Suh on 5/15/26.
//
//  Pencil .pen `Card/Quiz` — 선택 전/후 (O 정답 · X 오답) 상태 미러.
//

import SwiftUI

import Entity
import HomeDomainInterface
import PickeDesignKit

/// "오늘의 Pické — 퀴즈" 카드. 옵션 탭 → 정답 비교 → O/X 결과 라벨 노출.
struct QuizCardView: View {
  let question: QuizQuestion

  @State private var selectedOption: Choice?

  enum Choice: Equatable {
    case a
    case b
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      header()
      titleBlock()
      options()
    }
    .padding(.vertical, 20)
    .padding(.horizontal, 16)
    .roundedBackground(.beige400)
    .overlay(
      RoundedRectangle(cornerRadius: .radiusDefault).stroke(.beige700, lineWidth: 1)
    )
  }

  @ViewBuilder
  private func header() -> some View {
    HStack {
      TagBadgeView(text: "퀴즈")
      Spacer()
      Text("\(question.participantCount.formatted())명 참여")
        .pretendardFont(.medium11)
        .foregroundStyle(.neutral300)
    }
  }

  @ViewBuilder
  private func titleBlock() -> some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(question.title)
        .pretendardFont(.semiBold15)
        .foregroundStyle(.neutral900)
        .kerning(-0.375)
      Text(question.summary)
        .pretendardFont(.labelSmall)
        .foregroundStyle(.neutral200)
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
    }
  }

  @ViewBuilder
  private func options() -> some View {
    HStack(spacing: 8) {
      optionButton(.a, label: question.itemA, desc: question.itemADesc, isCorrect: question.isCorrectA)
      optionButton(.b, label: question.itemB, desc: question.itemBDesc, isCorrect: question.isCorrectB)
    }
  }

  @ViewBuilder
  private func optionButton(
    _ choice: Choice,
    label: String,
    desc: String,
    isCorrect: Bool
  ) -> some View {
    let isSelected = selectedOption == choice
    let hasAnswered = selectedOption != nil
    Button {
      selectedOption = isSelected ? nil : choice
    } label: {
      VStack(spacing: 2) {
        resultBadge(isSelected: isSelected, isCorrect: isCorrect)
        Text(label)
          .pretendardFont(.semiBold13)
          .foregroundStyle(.neutral900)
        Text(desc)
          .pretendardFont(.medium10)
          .foregroundStyle(.neutral300)
      }
      .frame(maxWidth: .infinity)
      .padding(12)
      .roundedBackground(.beige50)
      .overlay(
        RoundedRectangle(cornerRadius: .radiusDefault).stroke(.beige500, lineWidth: 1)
      )
      .opacity(hasAnswered && !isSelected ? 0.5 : 1)
    }
    .buttonStyle(.plain)
  }

  @ViewBuilder
  private func resultBadge(
    isSelected: Bool,
    isCorrect: Bool
  ) -> some View {
    if isSelected {
      Text(isCorrect ? "O 정답" : "X 오답")
        .pretendardFont(.labelXSmall)
        .foregroundStyle(isCorrect ? .secondary500 : .primary500)
    } else {
      Color.clear.frame(height: 14)
    }
  }
}
