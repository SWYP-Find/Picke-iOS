//
//  ExploreSort.swift
//  Entity
//

import Foundation

public enum ExploreSort: String, Equatable, Hashable, CaseIterable {
  case popular
  case latest

  public var title: String {
    switch self {
    case .popular: "인기순"
    case .latest: "최신순"
    }
  }

  /// 검색 API `sort` 쿼리 값 (대문자 영문 enum: POPULAR / LATEST).
  public var queryValue: String { rawValue.uppercased() }
}
