//
//  ClassAIFeedbackPoint.swift
//  ClassDomainInterface
//
//  Created by Picke on 10/12/26.
//

public struct ClassAIFeedbackPoint: Equatable, Sendable {
  public let title: String
  public let detail: String

  public init(
    title: String,
    detail: String
  ) {
    self.title = title
    self.detail = detail
  }
}
