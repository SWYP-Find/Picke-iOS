//
//  ShareItem.swift
//  Entity
//
//  공유 시트 트리거. `.sheet(item:)` 에 바로 바인딩한다. (PreVote / 오늘의 배틀 등 공용)
//

import Foundation

public struct ShareItem: Equatable, Identifiable {
  public let id: UUID
  public let items: [Any]

  public init(
    id: UUID = UUID(),
    items: [Any]
  ) {
    self.id = id
    self.items = items
  }

  public static func == (lhs: ShareItem, rhs: ShareItem) -> Bool {
    lhs.id == rhs.id
  }
}
