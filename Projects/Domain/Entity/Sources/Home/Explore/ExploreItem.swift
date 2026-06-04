//
//  ExploreItem.swift
//  Entity
//
//  탐색(Hi-Fi) 화면 리스트 아이템 도메인 모델. .pen `탐색 hifi 이미지` 기준.
//

import Foundation

public struct ExploreItemPage: Equatable {
  public let items: [ExploreItem]
  public let nextOffset: Int?
  public let hasNext: Bool

  public init(
    items: [ExploreItem],
    nextOffset: Int?,
    hasNext: Bool
  ) {
    self.items = items
    self.nextOffset = nextOffset
    self.hasNext = hasNext
  }
}

public struct ExploreItem: Equatable, Identifiable, Hashable {
  public let id: Int
  public let category: String
  public let title: String
  public let summary: String
  public let minutes: Int
  public let viewCount: Int
  public let imageURL: String?

  public init(
    id: Int,
    category: String,
    title: String,
    summary: String,
    minutes: Int,
    viewCount: Int,
    imageURL: String? = nil
  ) {
    self.id = id
    self.category = category
    self.title = title
    self.summary = summary
    self.minutes = minutes
    self.viewCount = viewCount
    self.imageURL = imageURL
  }
}

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

  /// 검색 API `category` 쿼리 값 (대문자 영문 enum). 전체는 nil(필터 없음).
  public var queryValue: String? {
    switch self {
    case .all: nil
    default: rawValue.uppercased()
    }
  }
}

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
