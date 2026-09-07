//
//  FormattingExtensionTests.swift
//  PickeCoreUtilityTests
//

import Foundation
import Testing

@testable import PickeCoreUtility

struct IntFormattingTests {
  @Test
  func 재생시간은_분과_초를_함께_표기한다() {
    #expect(125.durationText == "2분 5초")
    #expect(120.durationText == "2분")
    #expect(45.durationText == "45초")
  }

  @Test
  func 반올림_분_표기는_1분_미만도_1분으로_올린다() {
    #expect(20.roundedMinuteText == "1분")
    #expect(100.roundedMinuteText == "2분")
  }
}

struct StringSentenceTests {
  @Test
  func 문장부호를_포함해_분할한다() {
    #expect("안녕. 반가워! 잘가?".splitIntoSentences() == ["안녕.", " 반가워!", " 잘가?"])
  }

  @Test
  func 공백뿐인_조각은_버린다() {
    #expect("안녕.  \n".splitIntoSentences() == ["안녕."])
  }

  @Test
  func 문장부호가_없으면_원본_하나를_돌려준다() {
    #expect("문장부호 없음".splitIntoSentences() == ["문장부호 없음"])
  }
}
