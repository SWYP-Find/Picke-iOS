import Foundation

public struct ClassDebate: Equatable, Sendable {
  public let sessionID: Int
  public let status: ClassDebateStatus
  public let round: Int
  public let canReply: Bool
  public let canRetry: Bool
  public let philosopherName: String
  public let participantOptionTitle: String
  public let opponentOptionTitle: String
  public let messages: [ClassDebateMessage]
  public let aiNotice: String
  public let replyMinLength: Int
  public let replyMaxLength: Int

  public init(
    sessionID: Int,
    status: ClassDebateStatus,
    round: Int,
    canReply: Bool,
    canRetry: Bool,
    philosopherName: String,
    participantOptionTitle: String,
    opponentOptionTitle: String,
    messages: [ClassDebateMessage],
    aiNotice: String,
    replyMinLength: Int,
    replyMaxLength: Int
  ) {
    self.sessionID = sessionID
    self.status = status
    self.round = round
    self.canReply = canReply
    self.canRetry = canRetry
    self.philosopherName = philosopherName
    self.participantOptionTitle = participantOptionTitle
    self.opponentOptionTitle = opponentOptionTitle
    self.messages = messages
    self.aiNotice = aiNotice
    self.replyMinLength = replyMinLength
    self.replyMaxLength = replyMaxLength
  }
}
