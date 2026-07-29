//
//  PreVoteLayout.swift
//  Chat
//

import CoreGraphics

enum PreVoteLayout {
  static let contentOverlapTopOffset: CGFloat = 280
  static let backgroundImageHeight: CGFloat = 512
  static let imageToContentGradientHeight: CGFloat = 260
  static let rootContentSpacing: CGFloat = 40
  static let contentToOptionSpacing: CGFloat = 40
  static let optionCardHeight: CGFloat = 106
  static let contentHorizontalPadding: CGFloat = 16
  static let contentTopPadding: CGFloat = 80
  static let ctaHeight: CGFloat = 52
  static let ctaBottomSpacing: CGFloat = 40
  static let ctaHorizontalPadding: CGFloat = 16
  /// CTA 가 safeAreaInset 으로 스크롤 하단에 예약하는 총 높이(버튼 + 하단 여백).
  static let ctaReservedHeight: CGFloat = ctaHeight + ctaBottomSpacing
  /// CTA 는 safeAreaInset 이 예약하므로, 콘텐츠 하단 여백은 옵션과 CTA 사이 간격만 남긴다.
  static let contentBottomSpacing: CGFloat = rootContentSpacing
  static let snapshotWidth: CGFloat = 360

  /// 제목·요약 길이에 따라 그라데이션 여백을 동적으로 결정(3단계).
  /// 텍스트가 짧을수록 여백을 키워 콘텐츠를 아래로, 길수록 줄여 위로 끌어올린다.
  static func contentGradientSpacerHeight(
    titleLength: Int,
    summaryLength: Int
  ) -> CGFloat {
    switch titleLength + summaryLength {
    case ...60: 76
    case 61 ... 90: 60
    default: 52
    }
  }
}
