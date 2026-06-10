//
//  CommentFilter.swift
//  Entity
//

import Foundation

public enum CommentFilter: String, CaseIterable, Equatable {
  case all
  case optionA
  case optionB

  public var title: String {
    switch self {
    case .all: "전체"
    case .optionA: "A"
    case .optionB: "B"
    }
  }

  /// 서버 쿼리에 보낼 optionLabel — `all` 은 nil.
  public var queryLabel: String? {
    switch self {
    case .all: nil
    case .optionA: "A"
    case .optionB: "B"
    }
  }
}
