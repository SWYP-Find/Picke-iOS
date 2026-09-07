//
//  CustomAlertStateTests.swift
//  PickeSharedUITests
//

import Testing

@testable import PickeSharedUI

struct CustomAlertStateTests {
  @Test
  func 기본값은_확인_취소_비파괴_확인형이다() {
    let sut = CustomAlertState<CustomAlertAction>(title: "제목")

    #expect(sut.message.isEmpty)
    #expect(sut.confirmTitle == "확인")
    #expect(sut.cancelTitle == "취소")
    #expect(sut.isDestructive == false)
    #expect(sut.style == .confirmation)
  }

  @Test
  func 지정한_값이_그대로_담긴다() {
    let sut = CustomAlertState<CustomAlertAction>(
      title: "탈퇴",
      message: "되돌릴 수 없다",
      confirmTitle: "탈퇴하기",
      cancelTitle: "닫기",
      isDestructive: true,
      style: .withdraw
    )

    #expect(sut.title == "탈퇴")
    #expect(sut.message == "되돌릴 수 없다")
    #expect(sut.confirmTitle == "탈퇴하기")
    #expect(sut.cancelTitle == "닫기")
    #expect(sut.isDestructive)
    #expect(sut.style == .withdraw)
  }
}
