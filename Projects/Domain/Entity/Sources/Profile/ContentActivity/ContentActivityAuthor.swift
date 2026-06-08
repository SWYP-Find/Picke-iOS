//
//  ContentActivityAuthor.swift
//  Entity
//

import Foundation

public struct ContentActivityAuthor: Equatable {
  public let userTag: String
  public let nickname: String
  public let characterType: String
  public let characterImageURL: String

  public init(
    userTag: String,
    nickname: String,
    characterType: String,
    characterImageURL: String
  ) {
    self.userTag = userTag
    self.nickname = nickname
    self.characterType = characterType
    self.characterImageURL = characterImageURL
  }
}
