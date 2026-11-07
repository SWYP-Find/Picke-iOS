//
//  HomeBestCommentRow.swift
//  Home
//

import HomeDomainInterface
import PickeDesignKit
import SwiftUI
import UIKit

/// Best 댓글 행 — Android `HomeBestCommentItem` 시안.
/// 선택지 배지는 본문 첫 줄 앞에 inline 이미지로 붙여 본문과 함께 줄바꿈된다.
struct HomeBestCommentRow: View {
  let comment: HomeBestComment
  @Environment(\.displayScale) private var displayScale

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
  private var accessibilityText: String {
    let body = [comment.optionTitle, comment.content]
      .filter { !$0.isEmpty }
      .joined(separator: " ")
    return "\(comment.battleTitle), \(body)"
  }

  private var battleTitleText: some View {
    Text(comment.battleTitle)
      .pretendardFont(.semiBold13, lineHeightMultiple: 1.4)
      .foregroundStyle(.textMuted)
      .lineLimit(1)
      .truncationMode(.tail)
  }

  @ViewBuilder
  private func contentSection() -> some View {
    let badge = OptionBadgeImage.make(
      title: comment.optionTitle,
      scale: displayScale
    )
    HStack(alignment: .top, spacing: 0) {
      Image(asset: .replyCorner)
        .resizable()
        .frame(width: 16, height: 16)
        .foregroundStyle(.primary500)
      contentText(badge: badge)
        .pretendardFont(.regular13, lineHeightMultiple: 1.4)
        .foregroundStyle(.textSubtler)
        .lineLimit(2)
        .truncationMode(.tail)
        // SwiftUI 는 `.baselineOffset` 으로 내린 이미지도 줄 위쪽을 이미지 높이만큼 잡아 첫 줄 위가 빈다 → 그만큼 당긴다.
        .padding(.top, -(badge.map(badgeDescent) ?? 0))
        .padding(.horizontal, 2)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
  }

  private func contentText(badge: UIImage?) -> Text {
    guard let badge else {
      return Text(verbatim: comment.content)
    }
    let badgeText = Text(Image(uiImage: badge).renderingMode(.original))
      .baselineOffset(-badgeDescent(badge))
    return Text("\(badgeText)\(Text(verbatim: comment.content))")
  }

  /// 배지 세로 중앙을 본문 대문자 높이 중앙에 맞춘다(Android PlaceholderVerticalAlign.TextCenter).
  /// 반환값은 기준선 아래로 내려가는 배지 높이.
  private func badgeDescent(_ badge: UIImage) -> CGFloat {
    let capHeight = UIFont.pretendardFontFamily(family: .Regular, size: 13).capHeight
    return (badge.size.height - capHeight) / 2
  }
}

/// 선택지 배지 이미지 — 배경 radius 2, Medium 12, 가로 4·세로 2, 뒤쪽 투명 간격 4 포함.
@MainActor
private enum OptionBadgeImage {
  private static var cache: [String: UIImage] = [:]
  /// 선택지 제목은 서버에서 계속 바뀌므로 캐시가 쌓이지 않게 상한을 둔다.
  private static let cacheLimit = 64

  private static let horizontalPadding: CGFloat = 4
  private static let verticalPadding: CGFloat = 2
  private static let trailingSpacing: CGFloat = 4
  private static let cornerRadius: CGFloat = 2
  /// Android bodyXxsMedium 줄높이 1.4배.
  private static let lineHeight: CGFloat = 12 * 1.4

  static func make(
    title: String,
    scale: CGFloat
  ) -> UIImage? {
    guard !title.isEmpty else { return nil }
    let key = "\(title)|\(scale)"
    if let cached = cache[key] {
      return cached
    }

    let font = UIFont.pretendardFontFamily(family: .Medium, size: 12)
    let attributes: [NSAttributedString.Key: Any] = [
      .font: font,
      .foregroundColor: UIColor(Color.badgeFilledText),
    ]
    let textWidth = ceil((title as NSString).size(withAttributes: attributes).width)
    let badgeWidth = textWidth + horizontalPadding * 2
    let badgeHeight = lineHeight + verticalPadding * 2

    let format = UIGraphicsImageRendererFormat()
    format.scale = scale
    let renderer = UIGraphicsImageRenderer(
      size: CGSize(width: badgeWidth + trailingSpacing, height: badgeHeight),
      format: format
    )
    let image = renderer.image { _ in
      let badgeRect = CGRect(x: 0, y: 0, width: badgeWidth, height: badgeHeight)
      UIColor(Color.badgeFilledBackground).setFill()
      UIBezierPath(roundedRect: badgeRect, cornerRadius: cornerRadius).fill()
      let textOrigin = CGPoint(
        x: horizontalPadding,
        y: verticalPadding + (lineHeight - font.lineHeight) / 2
      )
      (title as NSString).draw(at: textOrigin, withAttributes: attributes)
    }
    if cache.count >= cacheLimit {
      cache.removeAll()
    }
    cache[key] = image
    return image
  }
}
