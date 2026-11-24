import Foundation

public struct ClassVoteStatsOption: Equatable, Identifiable, Sendable {
  public let id: Int
  public let title: String
  public let imageURL: URL?
  public let voteCount: Int
  public let ratio: Double

  public init(
    id: Int,
    title: String,
    imageURL: URL?,
    voteCount: Int,
    ratio: Double
  ) {
    self.id = id
    self.title = title
    self.imageURL = imageURL
    self.voteCount = voteCount
    self.ratio = ratio
  }
}
