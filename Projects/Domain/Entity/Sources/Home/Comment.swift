//
//  Comment.swift
//  Entity
//
//  picke.pen `댓글화면` (j3GDzL) 매핑 도메인 모델.
//

import Foundation

public enum CommentOption: Equatable {
  case a
  case b

  public var label: String {
    switch self {
    case .a: "A"
    case .b: "B"
    }
  }
}

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

public struct CommentReplyItem: Equatable, Identifiable {
  public let id: UUID
  public var commentId: Int?
  public var author: String
  public var timeAgo: String
  public var option: CommentOption
  public var content: String
  public var likeCount: Int
  public var isLiked: Bool
  public var createdOrder: Int

  public init(
    id: UUID = UUID(),
    commentId: Int? = nil,
    author: String,
    timeAgo: String,
    option: CommentOption,
    content: String,
    likeCount: Int,
    isLiked: Bool = false,
    createdOrder: Int
  ) {
    self.id = id
    self.commentId = commentId
    self.author = author
    self.timeAgo = timeAgo
    self.option = option
    self.content = content
    self.likeCount = likeCount
    self.isLiked = isLiked
    self.createdOrder = createdOrder
  }

  /// 서버 PerspectiveComment 응답을 화면 모델로 변환.
  public init(item: PerspectiveComment, parentOption: CommentOption, order: Int) {
    let id = UUID(uuidString: Self.deterministicUUID(commentId: item.commentId)) ?? UUID()
    self.init(
      id: id,
      commentId: item.commentId,
      author: item.user.nickname,
      timeAgo: Self.relativeTimeString(from: item.createdAt),
      option: parentOption,
      content: item.content,
      likeCount: item.likeCount,
      isLiked: item.isLiked,
      createdOrder: order
    )
  }

  private static func deterministicUUID(commentId: Int) -> String {
    let hex = String(format: "%012X", commentId)
    return "00000000-0000-0000-0002-\(hex)"
  }

  private static func relativeTimeString(from date: Date?) -> String {
    guard let date else { return "방금 전" }
    let interval = Date().timeIntervalSince(date)
    if interval < 60 { return "방금 전" }
    if interval < 3600 { return "\(Int(interval / 60))분 전" }
    if interval < 86400 { return "\(Int(interval / 3600))시간 전" }
    return "\(Int(interval / 86400))일 전"
  }

  public static func mocks(for option: CommentOption) -> [CommentReplyItem] {
    [
      .init(
        id: UUID(uuidString: "00000000-0000-0000-0001-000000000001") ?? UUID(),
        author: "사색하는 사슴",
        timeAgo: "2분 전",
        option: option,
        content: "네덜란드 사례를 일반화하기엔 무리가 있지 않나요? 한국의 사회문화적 맥락은 다릅니다.",
        likeCount: 1340,
        createdOrder: 3
      ),
      .init(
        id: UUID(uuidString: "00000000-0000-0000-0001-000000000002") ?? UUID(),
        author: "논쟁하는 사자",
        timeAgo: "2분 전",
        option: option,
        content: "제도 자체보다 사각지대를 줄이는 보완책을 같이 봐야 한다고 생각해요.",
        likeCount: 534,
        createdOrder: 2
      ),
      .init(
        id: UUID(uuidString: "00000000-0000-0000-0001-000000000003") ?? UUID(),
        author: "질문하는 독자",
        timeAgo: "5분 전",
        option: option == .a ? .b : .a,
        content: "반대 입장도 이해되지만, 개인의 자기결정권을 완전히 배제하기는 어렵지 않을까요?",
        likeCount: 219,
        createdOrder: 1
      ),
    ]
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
    self.createdOrder = createdOrder
  }

  /// API 응답 BattlePerspective 를 화면 모델로 변환.
  public init(item: BattlePerspective, order: Int) {
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
