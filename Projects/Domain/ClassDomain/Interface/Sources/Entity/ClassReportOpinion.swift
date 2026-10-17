//
//  ClassReportOpinion.swift
//  ClassDomainInterface
//
//  Created by Picke on 10/17/26.
//

public struct ClassReportOpinion: Equatable, Sendable {
  public let id: String
  public let kind: ClassReportOpinionKind
  public let body: String
  public let stance: String?
  public let likeCount: Int?
  public let replyCount: Int?
  public let authorName: String?
  public let parent: ClassReportReplyContext?

  public init(
    id: String,
    kind: ClassReportOpinionKind,
    body: String,
    stance: String? = nil,
    likeCount: Int? = nil,
    replyCount: Int? = nil,
    authorName: String? = nil,
    parent: ClassReportReplyContext? = nil
  ) {
    self.id = id
    self.kind = kind
    self.body = body
    self.stance = stance
    self.likeCount = likeCount
    self.replyCount = replyCount
    self.authorName = authorName
    self.parent = parent
  }
}
