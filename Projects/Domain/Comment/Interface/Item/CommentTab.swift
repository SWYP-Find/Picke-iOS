//
//  CommentTab.swift
//  Entity
//

import Foundation

public enum CommentTab: Equatable, Hashable {
  case all
  case option(label: String, title: String)

  public var title: String {
    switch self {
    case .all: "전체"
    case let .option(_, title): title
    }
  }

  public var optionLabel: String? {
    switch self {
    case .all: nil
    case let .option(label, _): label
    }
  }
}
