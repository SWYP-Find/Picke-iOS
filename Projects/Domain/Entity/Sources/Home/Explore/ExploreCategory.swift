//
//  ExploreCategory.swift
//  Entity
//

import Foundation

public enum ExploreCategory: String, Equatable, Hashable, CaseIterable, Identifiable {
  case all
  case philosophy
  case literature
  case art
  case science
  case society
  case history

  public var id: String { rawValue }

  public var title: String {
    switch self {
    case .all: "전체"
    case .philosophy: "철학"
    case .literature: "문학"
    case .art: "예술"
    case .science: "과학"
    case .society: "사회"
    case .history: "역사"
    }
  }

  /// 검색 API `category` 쿼리 값 (서버는 한글 카테고리명을 사용). 전체는 nil(필터 없음).
  public var queryValue: String? {
    switch self {
    case .all: nil
    default: title
    }
  }
}
