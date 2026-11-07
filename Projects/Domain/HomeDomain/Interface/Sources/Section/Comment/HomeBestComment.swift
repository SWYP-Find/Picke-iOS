//
//  HomeBestComment.swift
//  HomeDomainInterface
//

import Foundation

/// 홈 API가 제공하는 Best 댓글. 없는 battleId는 DTO 매핑에서 제외한다.
public struct HomeBestComment: Equatable, Identifiable {
  public let battleId: Int
  public let battleTitle: String
  public let optionTitle: String
  public let content: String

  public var id: Int {
    battleId
  }

  public init(
    battleId: Int,
    battleTitle: String,
    optionTitle: String,
    content: String
  ) {
    self.battleId = battleId
    self.battleTitle = battleTitle
    self.optionTitle = optionTitle
    self.content = content
  }
}
