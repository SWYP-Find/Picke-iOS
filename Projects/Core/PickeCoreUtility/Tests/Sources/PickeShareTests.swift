//
//  PickeShareTests.swift
//  PickeCoreUtilityTests
//

import Foundation
import Testing

@testable import PickeCoreUtility

struct PickeShareURLTests {
  @Test
  func 공유_링크는_실존하는_battle_단수_경로를_사용한다() {
    #expect(PickeShareURL.battle(id: 42) == "https://picke.store/battle/42")
  }

  @Test
  func 신뢰할_수_있는_picke_store_서버_링크만_사용한다() {
    #expect(
      PickeShareURL.battle(
        id: 42,
        serverShareUrl: "https://picke.store/battle/99"
      ) == "https://picke.store/battle/99"
    )
    #expect(
      PickeShareURL.battle(
        id: 42,
        serverShareUrl: "https://preview.picke.store/battle/99"
      ) == "https://preview.picke.store/battle/99"
    )
  }

  @Test
  func 신뢰할_수_없는_서버_링크는_검증된_랜딩_경로로_대체한다() {
    #expect(
      PickeShareURL.battle(
        id: 42,
        serverShareUrl: "https://pique.app/battles/42"
      ) == "https://picke.store/battle/42"
    )
  }
}

struct ShareUseCaseTests {
  @Test
  func 라이브_공유_클라이언트는_본문과_URL을_조립한다() async {
    let item = await ShareUseCase.liveValue.makeShareItem(
      ShareContent(
        title: "타이틀",
        summary: "요약",
        hashtags: ["#picke"],
        optionLine: nil,
        url: "https://picke.store/battle/42",
        thumbnailURL: nil,
        snapshotData: nil
      )
    )

    #expect(item.items.count == 2)
    #expect(item.items.first as? String == "타이틀\n\n요약\n\n#picke")
    #expect(item.items.last as? URL == URL(string: "https://picke.store/battle/42"))
  }
}
