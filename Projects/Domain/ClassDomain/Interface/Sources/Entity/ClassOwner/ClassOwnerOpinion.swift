import Foundation

public struct ClassOwnerOpinion: Equatable, Identifiable, Sendable {
  public let id: Int
  public let author: String
  public let text: String
  public let replyCount: Int
  public let recommendationCount: Int?
  public let createdAt: Date?
  public let isReported: Bool

  public init(
    id: Int,
    author: String,
    text: String,
    replyCount: Int,
    recommendationCount: Int? = nil,
    createdAt: Date? = nil,
    isReported: Bool = false
  ) {
    self.id = id
    self.author = author
    self.text = text
    self.replyCount = replyCount
    self.recommendationCount = recommendationCount
    self.createdAt = createdAt
    self.isReported = isReported
  }
}
