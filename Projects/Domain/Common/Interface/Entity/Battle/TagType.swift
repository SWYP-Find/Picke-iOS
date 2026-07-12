//
//  TagType.swift
//  CommonDomain
//

import Foundation

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
