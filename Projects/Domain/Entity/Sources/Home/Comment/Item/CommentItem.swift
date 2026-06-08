//
//  CommentItem.swift
//  Entity
//

import Foundation

public struct CommentItem: Equatable, Identifiable {
  public let id: UUID
  public var perspectiveId: Int?
  public var author: String
  public var authorImageURL: String?
  public var timeAgo: String
  public var option: CommentOption
  public var optionLabel: String?
  public var content: String
  public var replyCount: Int
  public var likeCount: Int
  public var isLiked: Bool
  public var isMine: Bool
  public var createdOrder: Int

  public init(
    id: UUID = UUID(),
    perspectiveId: Int? = nil,
    author: String,
    authorImageURL: String? = nil,
    timeAgo: String,
    option: CommentOption,
    optionLabel: String? = nil,
    content: String,
    replyCount: Int,
    likeCount: Int,
    isLiked: Bool = false,
    isMine: Bool = false,
    createdOrder: Int
  ) {
    self.id = id
    self.perspectiveId = perspectiveId
    self.author = author
    self.authorImageURL = authorImageURL
    self.timeAgo = timeAgo
    self.option = option
    self.optionLabel = optionLabel
    self.content = content
    self.replyCount = replyCount
    self.likeCount = likeCount
    self.isLiked = isLiked
    self.isMine = isMine
    self.createdOrder = createdOrder
  }

  /// API 응답 BattlePerspective 를 화면 모델로 변환.
  public init(
    item: BattlePerspective,
    order: Int
  ) {
    let optionFallback: CommentOption = item.option.label == "B" ? .b : .a
    self.init(
      id: UUID(uuidString: Self.deterministicUUID(perspectiveId: item.perspectiveId)) ?? UUID(),
      perspectiveId: item.perspectiveId,
      author: item.user.nickname,
      authorImageURL: item.user.characterImageUrl,
      timeAgo: Self.relativeTimeString(from: item.createdAt),
      option: optionFallback,
      optionLabel: item.option.title,
      content: item.content,
      replyCount: item.commentCount,
      likeCount: item.likeCount,
      isLiked: item.isLiked,
      isMine: item.isMyPerspective,
      createdOrder: order
    )
  }

  private static func deterministicUUID(perspectiveId: Int) -> String {
    let hex = String(format: "%012X", perspectiveId)
    return "00000000-0000-0000-0000-\(hex)"
  }

  private static func relativeTimeString(from date: Date?) -> String {
    guard let date else { return "방금 전" }
    let interval = Date().timeIntervalSince(date)
    if interval < 60 { return "방금 전" }
    if interval < 3600 { return "\(Int(interval / 60))분 전" }
    if interval < 86400 { return "\(Int(interval / 3600))시간 전" }
    return "\(Int(interval / 86400))일 전"
  }
}
