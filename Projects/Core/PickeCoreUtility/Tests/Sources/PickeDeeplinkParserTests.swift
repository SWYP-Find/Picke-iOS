//
//  PickeDeeplinkParserTests.swift
//  PickeCoreUtilityTests
//

import Foundation
import Testing

@testable import PickeCoreUtility

struct PickeDeeplinkParserTests {
  @Test
  func 커스텀_스킴의_host_를_리소스_타입으로_읽는다() {
    #expect(PickeDeeplinkParser.parse(urlString: "picke://battle/55") == .battle(battleId: 55))
  }

  @Test
  func 유니버설_링크의_commentId_쿼리를_함께_읽는다() {
    let link = PickeDeeplinkParser.parse(urlString: "https://picke.store/perspective/45?commentId=678")

    #expect(link == .perspective(perspectiveId: 45, commentId: 678))
  }

  @Test
  func 단일_경로는_포인트와_약관으로_매핑된다() {
    #expect(PickeDeeplinkParser.parse(urlString: "picke://credits") == .point)
    #expect(PickeDeeplinkParser.parse(urlString: "picke://policy") == .terms)
  }

  @Test
  func 식별자가_없으면_딥링크를_만들지_않는다() {
    #expect(PickeDeeplinkParser.parse(urlString: "picke://battle") == nil)
    #expect(PickeDeeplinkParser.parse(urlString: "picke://battle/none") == nil)
  }

  @Test
  func 푸시_payload_의_문자열_식별자도_숫자로_읽는다() {
    let link = PickeDeeplinkParser.parse(pushPayload: [
      "type": "COMMENT",
      "perspectiveId": "45",
      "commentId": 678,
    ])

    #expect(link == .perspective(perspectiveId: 45, commentId: 678))
  }

  @Test
  func DAILY_MESSAGE_푸시는_빠른_배틀로_이동한다() {
    #expect(
      PickeDeeplinkParser.parse(pushPayload: ["detailCode": "DAILY_MESSAGE"]) == .quickBattle
    )
    #expect(
      PickeDeeplinkParser.parse(pushPayload: [
        "detailCode": "DAILY_MESSAGE",
        "type": "BATTLE",
        "battleId": "7",
        "url": "picke://battle/7",
      ]) == .quickBattle
    )
  }

  @Test
  func 푸시와_알림함은_같은_detailCode_매핑을_사용한다() {
    for code in ["NEW_BATTLE", "NEW_COMMENT", "COMMENT_LIKE", "CREDIT_EARNED", "POLICY_CHANGE", "DAILY_MESSAGE"] {
      #expect(
        PickeDeeplinkParser.parse(pushPayload: [
          "detailCode": code,
          "referenceId": "9",
          "perspectiveId": "4",
        ]) == PickeDeeplinkParser.parse(
          detailCode: code,
          referenceId: 9,
          perspectiveId: 4
        )
      )
    }
  }

  @Test
  func 매핑할_수_없는_detailCode는_type과_URL로_폴백한다() {
    #expect(PickeDeeplinkParser.parse(pushPayload: [
      "detailCode": "UNKNOWN",
      "type": "BATTLE",
      "battleId": "7",
      "url": "picke://point",
    ]) == .battle(battleId: 7))
    #expect(PickeDeeplinkParser.parse(pushPayload: [
      "detailCode": "NEW_BATTLE",
      "url": "picke://point",
    ]) == .point)
    #expect(PickeDeeplinkParser.parse(pushPayload: ["detailCode": "UNKNOWN"]) == nil)
  }

  @Test
  func 푸시_type_이_없으면_url_로_폴백한다() {
    let link = PickeDeeplinkParser.parse(pushPayload: ["url": "picke://battle/7"])

    #expect(link == .battle(battleId: 7))
  }

  @Test
  func 알림함_detailCode_를_딥링크로_바꾼다() {
    #expect(
      PickeDeeplinkParser.parse(detailCode: "NEW_BATTLE", referenceId: 3, perspectiveId: nil)
        == .battle(battleId: 3)
    )
    #expect(
      PickeDeeplinkParser.parse(detailCode: "NEW_COMMENT", referenceId: 9, perspectiveId: 4)
        == .perspective(perspectiveId: 4, commentId: 9)
    )
    #expect(
      PickeDeeplinkParser.parse(detailCode: "DAILY_MESSAGE", referenceId: nil, perspectiveId: nil)
        == .quickBattle
    )
    #expect(
      PickeDeeplinkParser.parse(detailCode: "PROMOTION", referenceId: 1, perspectiveId: 1) == nil
    )
  }

  @Test
  func encoded_문자열은_다시_같은_딥링크로_복원된다() {
    let links: [PickeDeeplink] = [
      .battle(battleId: 55),
      .perspective(perspectiveId: 45, commentId: 678),
      .perspective(perspectiveId: 45, commentId: nil),
      .point,
      .terms,
      .quickBattle,
    ]

    for link in links {
      #expect(PickeDeeplinkParser.parse(urlString: "picke://\(link.encoded)") == link)
    }
  }
}
