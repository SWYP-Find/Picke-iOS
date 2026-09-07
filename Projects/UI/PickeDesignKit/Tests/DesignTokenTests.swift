//
//  DesignTokenTests.swift
//  PickeDesignKitTests
//

import CoreGraphics
import Testing

@testable import PickeDesignKit

/// 토큰 값 자체는 생성기가 만든다. 여기서는 화면 코드가 기대는 관계만 고정한다.
struct DesignTokenTests {
  @Test
  func 간격_토큰은_단조_증가한다() {
    let scale: [CGFloat] = [.s0, .s2, .s4, .s6, .s8, .s12, .s16, .s20, .s24, .s32, .s40, .s48, .s64, .s80, .s96]

    #expect(zip(scale, scale.dropFirst()).allSatisfy { $0 < $1 })
  }

  @Test
  func 아이콘과_아바타_크기는_단계별로_커진다() {
    #expect(CGFloat.iconXs < .iconSm)
    #expect(CGFloat.iconSm < .iconMd)
    #expect(CGFloat.iconMd < .iconLg)
    #expect(CGFloat.avatarSm < .avatarMd)
    #expect(CGFloat.avatarMd < .avatarLg)
  }

  /// 알약 모양을 만드는 값이라 어떤 컴포넌트 높이보다도 커야 한다.
  @Test
  func radiusMax_는_기본_radius_보다_충분히_크다() {
    #expect(CGFloat.radiusMax > .controlMd)
    #expect(CGFloat.radiusDefault < .radiusMax)
  }

  @Test
  func 테두리_두께는_regular_medium_large_순이다() {
    #expect(CGFloat.borderWidthRegular < .borderWidthMedium)
    #expect(CGFloat.borderWidthMedium < .borderWidthLarge)
  }
}
