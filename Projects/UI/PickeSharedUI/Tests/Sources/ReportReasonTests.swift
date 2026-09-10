//
//  ReportReasonTests.swift
//  PickeSharedUITests
//

import Testing

@testable import PickeSharedUI

struct ReportReasonTests {
  /// 신고 사유를 추가하고 컬럼 배치를 잊으면 그 항목이 화면에서 통째로 사라진다.
  @Test
  func 두_컬럼이_모든_사유를_중복_없이_담는다() {
    let placed = ReportReason.leftColumn + ReportReason.rightColumn

    #expect(Set(placed) == Set(ReportReason.allCases))
    #expect(placed.count == ReportReason.allCases.count)
  }

  @Test
  func 모든_사유가_서로_다른_제목을_갖는다() {
    let titles = ReportReason.allCases.map(\.title)

    #expect(Set(titles).count == ReportReason.allCases.count)
    #expect(titles.allSatisfy { !$0.isEmpty })
  }

  @Test
  func id_는_rawValue_다() {
    #expect(ReportReason.allCases.allSatisfy { $0.id == $0.rawValue })
  }
}
