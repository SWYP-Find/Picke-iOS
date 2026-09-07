//
//  ExploreItem.swift
//  Entity
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
