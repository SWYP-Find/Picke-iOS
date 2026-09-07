//
//  CommunityActionData.swift
//  UseCase
//

import Foundation

public struct CommunityActionData: Sendable {
  public let contentID: String
  public let commentLength: Int

  public init(contentID: String, commentLength: Int) {
    self.contentID = contentID
    self.commentLength = commentLength
  }
}
