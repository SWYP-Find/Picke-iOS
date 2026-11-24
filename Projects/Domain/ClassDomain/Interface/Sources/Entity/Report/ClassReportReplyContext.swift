//
//  ClassReportReplyContext.swift
//  ClassDomainInterface
//
//  Created by Picke on 10/17/26.
//

public struct ClassReportReplyContext: Equatable, Sendable {
  public let authorName: String?
  public let stance: String?
  public let body: String

  public init(
    authorName: String? = nil,
    stance: String? = nil,
    body: String
  ) {
    self.authorName = authorName
    self.stance = stance
    self.body = body
  }
}
