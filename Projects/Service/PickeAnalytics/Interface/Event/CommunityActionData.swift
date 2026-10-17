//
//  CommunityActionData.swift
//  PickeAnalyticsInterface
//
//  Created by Picke on 10/11/26.
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
