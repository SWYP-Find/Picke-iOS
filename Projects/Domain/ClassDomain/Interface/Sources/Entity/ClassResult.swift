import Foundation

public struct ClassResult: Equatable, Sendable {
  public let classID: Int
  public let closed: Bool
  public let closeAt: Date
  public let stats: ClassResultStats
  public let myReportState: String?
  public let insightState: String?

  public init(
    classID: Int,
    closed: Bool,
    closeAt: Date,
    stats: ClassResultStats,
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
