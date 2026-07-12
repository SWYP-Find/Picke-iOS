//
//  ExploreItem.swift
//  Entity
//
//  탐색(Hi-Fi) 화면 리스트 아이템 도메인 모델. .pen `탐색 hifi 이미지` 기준.
//

import Foundation

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
