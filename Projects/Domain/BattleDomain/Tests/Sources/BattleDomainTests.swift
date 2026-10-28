//
//  BattleDomainTests.swift
//  BattleDomainTests
//
//  Created by Picke on 10/11/26.
//

@testable import BattleDomain
import Foundation
import Testing

struct BattleDomainTests {
  @Test
  func battleDomainExample() {
    #expect(true)
  }

  @Test
  func interactiveOptionPreservesServerID() throws {
    let json = Data(#"{"optionId":9001,"label":"유죄","nextNodeId":802}"#.utf8)
    let option = try #require(JSONDecoder().decode(ScenarioInteractiveOptionDTO.self, from: json).toDomain())

    #expect(option.optionID == 9001)
    #expect(option.label == "유죄")
    #expect(option.nextNodeId == 802)
  }

  @Test
  func interactiveOptionFallsBackToTitleAndSkipsMissingNextNode() throws {
    let titleOnly = Data(#"{"optionId":9001,"title":"피고인의 사정을 듣는다","nextNodeId":802}"#.utf8)
    let option = try #require(JSONDecoder().decode(ScenarioInteractiveOptionDTO.self, from: titleOnly).toDomain())
    #expect(option.label == "피고인의 사정을 듣는다")
    #expect(option.title == "피고인의 사정을 듣는다")

    let missingNext = Data(#"{"optionId":9002,"label":"유죄","title":"유죄를 선택한다"}"#.utf8)
    #expect(try JSONDecoder().decode(ScenarioInteractiveOptionDTO.self, from: missingNext).toDomain() == nil)
  }
}
