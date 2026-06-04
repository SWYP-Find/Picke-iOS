//
//  BattleTag.swift
//  Entity
//
//  Created by Wonji Suh on 5/16/26.
//

import Foundation

/// 홈 API 의 `tags` 항목 (id + 이름 + 분류 타입).
public struct BattleTag: Equatable, Identifiable, Hashable {
  public let tagId: Int
  public let name: String
  public let type: TagType

  public var id: Int { tagId }

  public init(
    tagId: Int,
    name: String,
    type: TagType
  ) {
    self.tagId = tagId
    self.name = name
    self.type = type
  }
}

public enum TagType: String, Equatable, Hashable, Decodable {
  case philosopher = "PHILOSOPHER"
  case category = "CATEGORY"
  case era = "ERA"
  case value = "VALUE"
  case unknown

  public init(rawValue: String) {
    switch rawValue {
    case "PHILOSOPHER": self = .philosopher
    case "CATEGORY": self = .category
    case "ERA": self = .era
    case "VALUE": self = .value
    default: self = .unknown
    }
  }

  public init(from decoder: Decoder) throws {
    let raw = try decoder.singleValueContainer().decode(String.self)
    self = TagType(rawValue: raw)
  }
}
