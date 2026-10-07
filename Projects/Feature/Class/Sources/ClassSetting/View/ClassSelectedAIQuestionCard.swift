//
//  ClassSelectedAIQuestionCard.swift
//  Class
//

import PickeDesignKit
import SwiftUI

struct ClassSelectedAIQuestionCard: View {
  let question: ClassAIQuestion

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      VStack(alignment: .leading, spacing: 12) {
        Text("#\(question.category)")
          .pickeBadge(.filled, size: .tag)

        VStack(alignment: .leading, spacing: 4) {
          Text(question.title)
            .pretendardFont(.headingSmall)
            .foregroundStyle(.gray500)
          Text(question.summary)
            .pretendardFont(.labelSmall)
            .foregroundStyle(.gray300)
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
    .pickeCard(.beige50, border: .beige600, radius: 0)
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
