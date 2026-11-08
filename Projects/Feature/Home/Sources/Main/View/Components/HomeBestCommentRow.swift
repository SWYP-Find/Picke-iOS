//
//  HomeBestCommentRow.swift
//  Home
//

import HomeDomainInterface
import PickeDesignKit
import SwiftUI
import UIKit

/// Best 댓글 행 — Android `HomeBestCommentItem` 시안.
/// 본문 첫 줄 앞에 배지 폭만큼 투명 자리를 두고, 선택지 배지는 첫 줄 기준선에 overlay 로 겹친다.
/// Android 처럼 배지가 글꼴보다 위·아래로 튀어나온 만큼만 본문 위·아래를 늘리고 줄 간격(13 × 1.4)은 그대로 둔다.
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
  /// 본문 글꼴(Android bodyXsRegular) — 배지 위치 계산과 한 곳에서 맞춘다.
  private static let contentFont: CustomSizeFont = .regular13
  private static let contentLineHeightMultiple: CGFloat = 1.4

  private var accessibilityText: String {
    let commentText = [comment.optionTitle, comment.content]
      .filter { !$0.isEmpty }
      .joined(separator: " ")
    return [comment.battleTitle, commentText]
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
        .pretendardFont(Self.contentFont, lineSpacingMultiple: Self.contentLineHeightMultiple)
        .foregroundStyle(.textSubtler)
        .lineLimit(2)
        .truncationMode(.tail)
        // 배지를 Text 안에 넣으면 SwiftUI 가 줄 위쪽을 배지 높이만큼 잡는다 → 본문엔 투명 자리만 두고 배지는 첫 줄 기준선에 겹친다.
        .overlay(alignment: Alignment(horizontal: .leading, vertical: .firstTextBaseline)) {
          if let badge {
            Image(uiImage: badge)
              .renderingMode(.original)
              .alignmentGuide(.firstTextBaseline) { [descent = badgeDescent(badge)] dimension in
                dimension.height - descent
              }
          }
        }
        .padding(.top, badge.map(badgeTopOverflow) ?? 0)
        .padding(.bottom, badge.map(badgeBottomOverflow) ?? 0)
        .padding(.horizontal, 2)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
  }

  private func contentText(badge: UIImage?) -> Text {
    guard let badge else {
      return Text(verbatim: comment.content)
    }
    let placeholderText = Text(Image(uiImage: OptionBadgeImage.placeholder(for: badge)))
    return Text("\(placeholderText)\(Text(verbatim: comment.content))")
  }

  private static var contentUIFont: UIFont {
    UIFont.pretendardFontFamily(
      family: contentFont.fontFamily,
      size: contentFont.size
    )
  }

  /// 배지 세로 중앙을 본문 글꼴 (ascent − descent) / 2 에 맞춘다(Android PlaceholderVerticalAlign.TextCenter).
  /// 반환값은 기준선 아래로 내려가는 배지 높이.
  private func badgeDescent(_ badge: UIImage) -> CGFloat {
    let font = Self.contentUIFont
    let textCenter = (font.ascender + font.descender) / 2
    return badge.size.height / 2 - textCenter
  }

  /// 배지 위가 글꼴 ascent 보다 높은 만큼 — Android 는 첫 줄 위쪽이 이만큼 늘어난다(Trim.Both 는 글꼴 수치 기준).
  private func badgeTopOverflow(_ badge: UIImage) -> CGFloat {
    let badgeTop = badge.size.height - badgeDescent(badge)
    return max(0, badgeTop - Self.contentUIFont.ascender)
  }

  /// 배지 아래가 글꼴 descent 보다 낮은 만큼 — Android 는 첫 줄 글꼴 수치를 마지막 줄에도 써서 본문 아래가 이만큼 늘어난다.
  private func badgeBottomOverflow(_ badge: UIImage) -> CGFloat {
    max(0, badgeDescent(badge) + Self.contentUIFont.descender)
  }
}

/// 선택지 배지 이미지 — 배경 radius 2, Medium 12(Android bodyXxsMedium, 한 줄이라 자연 높이), 가로 4·세로 2, 뒤쪽 투명 간격 4 포함.
@MainActor
private enum OptionBadgeImage {
  private static var cache: [String: UIImage] = [:]
  /// 선택지 제목은 서버에서 계속 바뀌므로 캐시가 쌓이지 않게 상한을 둔다.
  private static let cacheLimit = 64

  private static let horizontalPadding: CGFloat = 4
  private static let verticalPadding: CGFloat = 2
  private static let trailingSpacing: CGFloat = 4
  private static let cornerRadius: CGFloat = 2
  private static let badgeFont: CustomSizeFont = .labelSmall

  static func make(
    title: String,
    scale: CGFloat
  ) -> UIImage? {
    guard !title.isEmpty else { return nil }
    let key = "\(title)|\(scale)"
    if let cached = cache[key] {
      return cached
    }

    let font = UIFont.pretendardFontFamily(
      family: badgeFont.fontFamily,
      size: badgeFont.size
    )
    let attributes: [NSAttributedString.Key: Any] = [
      .font: font,
      .foregroundColor: UIColor(Color.badgeFilledText),
    ]
    let textWidth = ceil((title as NSString).size(withAttributes: attributes).width)
    let badgeWidth = textWidth + horizontalPadding * 2
    let badgeHeight = font.lineHeight + verticalPadding * 2

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
        y: verticalPadding
      )
      (title as NSString).draw(at: textOrigin, withAttributes: attributes)
    }
    if cache.count >= cacheLimit {
      cache.removeAll()
    }
    cache[key] = image
    return image
  }

  /// 본문 안에서 배지 폭만 차지하는 투명 자리 — 높이 1이라 줄 위쪽 높이를 바꾸지 않는다.
  static func placeholder(for badge: UIImage) -> UIImage {
    let format = UIGraphicsImageRendererFormat()
    format.scale = badge.scale
    let renderer = UIGraphicsImageRenderer(
      size: CGSize(width: badge.size.width, height: 1),
      format: format
    )
    return renderer.image { _ in }
  }
}
