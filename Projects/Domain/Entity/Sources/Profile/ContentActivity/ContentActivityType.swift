//
//  ContentActivityType.swift
//  Entity
//

import Foundation

/// 콘텐츠 활동 유형 (탭).
public enum ContentActivityType: String, Equatable, CaseIterable, Identifiable {
  case comment = "COMMENT"
  case like = "LIKE"

  public var id: String { rawValue }

  /// 탭 표시명.
  public var title: String {
    switch self {
    case .comment: "내 댓글"
    case .like: "좋아요"
    }
  }

  public init(rawValue: String) {
    switch rawValue.uppercased() {
    case "LIKE": self = .like
    default: self = .comment
    }
  }
}
