//
//  Comment.swift
//  Entity
//
//  picke.pen `댓글화면` (j3GDzL) 매핑 도메인 모델.
//

import Foundation

public struct CommentAuthor: Equatable, Hashable {
  public let name: String
  public let imageURL: String?
  public let optionLabel: String?

  public init(name: String, imageURL: String? = nil, optionLabel: String? = nil) {
    self.name = name
    self.imageURL = imageURL
    self.optionLabel = optionLabel
  }
}

public struct Comment: Equatable, Identifiable, Hashable {
  public let id: Int
  public let author: CommentAuthor
  public let text: String
  public let createdAt: Date
  public let likeCount: Int
  public let replyCount: Int
  public let isLiked: Bool

  public init(
    id: Int,
    author: CommentAuthor,
    text: String,
    createdAt: Date,
    likeCount: Int,
    replyCount: Int,
    isLiked: Bool
  ) {
    self.id = id
    self.author = author
    self.text = text
    self.createdAt = createdAt
    self.likeCount = likeCount
    self.replyCount = replyCount
    self.isLiked = isLiked
  }
}

public enum CommentSortType: String, Equatable, Hashable, CaseIterable {
  case popular = "POPULAR"
  case latest = "LATEST"

  public var title: String {
    switch self {
    case .popular: "인기순"
    case .latest: "최신순"
    }
  }
}

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
