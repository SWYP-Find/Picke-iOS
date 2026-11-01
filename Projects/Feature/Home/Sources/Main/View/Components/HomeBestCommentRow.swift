//
//  HomeBestCommentRow.swift
//  Home
//

import HomeDomainInterface
import PickeDesignKit
import SwiftUI

struct HomeBestCommentRow: View {
  let comment: HomeBestComment

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(comment.battleTitle)
        .pretendardFont(.semiBold12)
        .foregroundStyle(.neutral300)
        .lineLimit(1)

      HStack(alignment: .top, spacing: 4) {
        Image(systemName: "arrow.turn.down.right")
          .foregroundStyle(.primary500)
          .frame(width: 16, height: 16)
        Text(attributedContent)
          .pretendardFont(.bodySmall)
          .foregroundStyle(.neutral500)
          .lineLimit(2)
          .frame(maxWidth: .infinity, alignment: .leading)
      }
    }
    .padding(16)
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private var attributedContent: AttributedString {
    guard !comment.optionTitle.isEmpty else {
      return AttributedString(comment.content)
    }
    var text = AttributedString(" \(comment.optionTitle)  \(comment.content)")
    if let range = text.range(of: comment.optionTitle) {
      text[range].foregroundColor = .primary500
      text[range].backgroundColor = .beige600
    }
    return text
  }
}
