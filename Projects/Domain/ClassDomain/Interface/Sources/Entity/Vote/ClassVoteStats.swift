import Foundation

public struct ClassVoteStats: Equatable, Sendable {
  public let options: [ClassVoteStatsOption]
  public let totalCount: Int
  public let updatedAt: Date

  public init(
    options: [ClassVoteStatsOption],
    totalCount: Int,
    updatedAt: Date
  ) {
    self.options = options
    self.totalCount = totalCount
    self.updatedAt = updatedAt
  }
}
