//
//  ClassAIQuestionCard.swift
//  Class
//
//  Created by Picke on 10/11/26.
//

import PickeDesignKit
import SwiftUI

struct ClassAIQuestionCard: View {
  let question: ClassAIQuestion
  let isSelected: Bool
  private let showsSelection: Bool

  init(question: ClassAIQuestion, isSelected: Bool) {
    self.init(question: question, isSelected: isSelected, showsSelection: true)
  }

  private init(question: ClassAIQuestion, isSelected: Bool, showsSelection: Bool) {
    self.question = question
    self.isSelected = isSelected
    self.showsSelection = showsSelection
  }

  func selectionIndicatorHidden() -> Self {
    Self(question: question, isSelected: isSelected, showsSelection: false)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      VStack(alignment: .leading, spacing: showsSelection ? 16 : 12) {
        HStack {
          Text("#\(question.category)")
            .pickeBadge(.filled, size: .tag)
          if showsSelection {
            Spacer()
            Image(systemName: "checkmark")
              .pickeCheckbox(isChecked: isSelected)
          }
        }

        VStack(alignment: .leading, spacing: 4) {
          Text(question.title)
            .pretendardFont(.headingSmall)
            .foregroundStyle(.gray500)
            .lineLimit(showsSelection ? 2 : nil)
          Text(question.summary)
            .pretendardFont(.labelSmall)
            .foregroundStyle(.gray300)
            .lineLimit(showsSelection ? 2 : nil)
        }
      }

      HStack(spacing: 8) {
        option(title: question.optionATitle, description: question.optionADescription)
        Text("VS")
          .pretendardFont(.bold8)
          .foregroundStyle(.gray900)
          .frame(width: 24, height: 24)
          .background(.secondary200, in: Circle())
        option(title: question.optionBTitle, description: question.optionBDescription)
      }
    }
    .padding(12)
    .frame(maxWidth: .infinity, alignment: .leading)
    .pickeCard(
      .beige50,
      border: isSelected ? .primary500 : .beige600,
      radius: showsSelection ? .radiusDefault : 0
    )
    .contentShape(Rectangle())
  }

  private func option(title: String, description: String) -> some View {
    VStack(alignment: .leading, spacing: 2) {
      Text(title)
        .pretendardFont(.semiBold11)
        .foregroundStyle(.gray500)
        .lineLimit(1)
      Text(description)
        .pretendardFont(.regular10)
        .foregroundStyle(.gray300)
        .lineLimit(1)
    }
    .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
    .padding(.horizontal, 8)
    .pickeCard(.beige300, border: .beige600)
  }
}
