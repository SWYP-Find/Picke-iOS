import Foundation

public struct ClassPerspectiveAuthor: Equatable, Sendable {
  public let userTag: String
  public let nickname: String
  public let characterType: String?
  public let characterImageURL: URL?

  public init(
    userTag: String,
    nickname: String,
    characterType: String?,
    characterImageURL: URL?
  ) {
    self.userTag = userTag
    self.nickname = nickname
    self.characterType = characterType
    self.characterImageURL = characterImageURL
  }
}
