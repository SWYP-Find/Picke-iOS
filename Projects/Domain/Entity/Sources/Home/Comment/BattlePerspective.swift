//
//  BattlePerspective.swift
//  Entity
//
//  `GET /api/v1/battles/{battleId}/perspectives` 응답 도메인 모델.
//  댓글(=관점) 리스트 + 커서 페이지네이션.
//

import Foundation

public struct BattlePerspectivePage: Equatable {
  public let items: [BattlePerspective]
  public let nextCursor: String?
  public let hasNext: Bool

  public init(items: [BattlePerspective], nextCursor: String?, hasNext: Bool) {
    self.items = items
    self.nextCursor = nextCursor
    self.hasNext = hasNext
  }
}

public struct BattlePerspective: Equatable, Identifiable, Hashable {
  public let perspectiveId: Int
  public let user: BattlePerspectiveUser
  public let option: BattlePerspectiveOption
  public let content: String
  public let likeCount: Int
  public let commentCount: Int
  public let isLiked: Bool
  public let isMyPerspective: Bool
  public let createdAt: Date?

  public var id: Int { perspectiveId }

  public init(
    perspectiveId: Int,
    user: BattlePerspectiveUser,
    option: BattlePerspectiveOption,
    content: String,
    likeCount: Int,
    commentCount: Int,
    isLiked: Bool,
    isMyPerspective: Bool,
    createdAt: Date?
  ) {
    self.perspectiveId = perspectiveId
    self.user = user
    self.option = option
    self.content = content
    self.likeCount = likeCount
    self.commentCount = commentCount
    self.isLiked = isLiked
    self.isMyPerspective = isMyPerspective
    self.createdAt = createdAt
  }
}

public struct BattlePerspectiveUser: Equatable, Hashable {
  public let userTag: String
  public let nickname: String
  public let characterType: String
  public let characterImageUrl: String?

  public init(
    userTag: String,
    nickname: String,
    characterType: String,
    characterImageUrl: String?
  ) {
    self.userTag = userTag
    self.nickname = nickname
    self.characterType = characterType
    self.characterImageUrl = characterImageUrl
  }
}

public struct BattlePerspectiveOption: Equatable, Hashable, Identifiable {
  public let optionId: Int
  public let label: String?
  public let title: String
  public let stance: String

  public var id: Int { optionId }

  public init(optionId: Int, label: String?, title: String, stance: String) {
    self.optionId = optionId
    self.label = label
    self.title = title
    self.stance = stance
  }
}

public enum BattlePerspectiveSort: String, Equatable, Hashable, CaseIterable {
  case popular
  case latest

  public var queryValue: String { rawValue }

  public var title: String {
    switch self {
    case .popular: "인기순"
    case .latest: "최신순"
    }
  }
}
