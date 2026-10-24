import Foundation

public struct ClassResult: Equatable, Sendable {
  public struct Option: Equatable, Identifiable, Sendable {
    public let id: Int
    public let title: String
    public let preVoteCount: Int
    public let postVoteCount: Int
    public let postVoteRatio: Double

    public init(id: Int, title: String, preVoteCount: Int, postVoteCount: Int, postVoteRatio: Double) {
      self.id = id
      self.title = title
      self.preVoteCount = preVoteCount
      self.postVoteCount = postVoteCount
      self.postVoteRatio = postVoteRatio
    }
  }

  public struct Stats: Equatable, Sendable {
    public let activeMemberCount: Int
    public let completedCount: Int
    public let participationRate: Double
    public let commentWriterCount: Int
    public let commentRate: Double
    public let postVoteCount: Int
    public let options: [Option]

    public init(
      activeMemberCount: Int,
      completedCount: Int,
      participationRate: Double,
      commentWriterCount: Int,
      commentRate: Double,
      postVoteCount: Int,
      options: [Option]
    ) {
      self.activeMemberCount = activeMemberCount
      self.completedCount = completedCount
      self.participationRate = participationRate
      self.commentWriterCount = commentWriterCount
      self.commentRate = commentRate
      self.postVoteCount = postVoteCount
      self.options = options
    }
  }

  public let classID: Int
  public let closed: Bool
  public let closeAt: Date
  public let stats: Stats
  public let myReportState: String?
  public let insightState: String?

  public init(
    classID: Int,
    closed: Bool,
    closeAt: Date,
    stats: Stats,
    myReportState: String?,
    insightState: String?
  ) {
    self.classID = classID
    self.closed = closed
    self.closeAt = closeAt
    self.stats = stats
    self.myReportState = myReportState
    self.insightState = insightState
  }
}
