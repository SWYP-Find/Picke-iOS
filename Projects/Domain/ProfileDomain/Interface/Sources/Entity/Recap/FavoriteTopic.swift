//
//  FavoriteTopic.swift
//  ProfileDomainInterface
//
//  Created by Picke on 10/11/26.
//

import Foundation

public struct FavoriteTopic: Equatable, Identifiable {
  public let rank: Int
  public let tagName: String
  public let participationCount: Int

  public var id: Int { rank }

  /// `#` 태그 표시.
  public var tagText: String {
    tagName.hasPrefix("#") ? tagName : "#\(tagName)"
  }

  public init(rank: Int, tagName: String, participationCount: Int) {
    self.rank = rank
    self.tagName = tagName
    self.participationCount = participationCount
  }
}
