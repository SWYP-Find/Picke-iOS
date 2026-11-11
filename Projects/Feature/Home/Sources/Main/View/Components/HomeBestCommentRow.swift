//
//  HomeBestCommentRow.swift
//  Home
//

import HomeDomainInterface
import PickeDesignKit
import SwiftUI

/// Best 댓글 행 — Android `HomeBestCommentItem` 시안 (배틀 제목 1줄 + 답글 아이콘 + 본문 2줄).
struct HomeBestCommentRow: View {
  let comment: HomeBestComment

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      battleTitleText
      contentSection()
    }
    .padding(16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(accessibilityText)
    .accessibilityAddTraits(.isButton)
  }
}

extension HomeBestCommentRow {
  /// Android bodyXsRegular + lineHeight 20.2sp (13 × 1.4 기준 줄 간격).
  private static let contentLineHeightMultiple: CGFloat = 1.4

  private var accessibilityText: String {
    [comment.battleTitle, comment.content]
      .filter { !$0.isEmpty }
      .joined(separator: ", ")
  }

  private var battleTitleText: some View {
    Text(comment.battleTitle)
      .pretendardFont(.semiBold13)
      .foregroundStyle(.textMuted)
      .lineLimit(1)
      .truncationMode(.tail)
  }

  @ViewBuilder
  private func contentSection() -> some View {
    HStack(alignment: .top, spacing: 0) {
      Image(asset: .replyCorner)
        .resizable()
        .frame(width: 16, height: 16)
        .foregroundStyle(.primary500)
      Text(verbatim: comment.content)
        .pretendardFont(.regular13, lineSpacingMultiple: Self.contentLineHeightMultiple)
        .foregroundStyle(.textSubtler)
        .lineLimit(2)
        .truncationMode(.tail)
        .padding(.horizontal, 2)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
  }
}
