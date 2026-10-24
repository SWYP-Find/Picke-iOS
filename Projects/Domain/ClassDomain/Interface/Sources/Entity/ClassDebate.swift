import Foundation

public struct ClassDebate: Equatable, Sendable {
  public enum Status: String, Equatable, Sendable {
    case generating = "GENERATING"
    case waitingUser = "WAITING_USER"
    case failed = "FAILED"
    case completed = "COMPLETED"
  }

  public struct Message: Equatable, Identifiable, Sendable {
    public enum Speaker: String, Equatable, Sendable {
      case ai = "AI"
      case user = "USER"
    }

    public let id: Int
    public let round: Int
    public let speaker: Speaker
    public let content: String

    public init(id: Int, round: Int, speaker: Speaker, content: String) {
      self.id = id
      self.round = round
      self.speaker = speaker
      self.content = content
    }
  }

  public let sessionID: Int
  public let status: Status
  public let round: Int
  public let canReply: Bool
  public let canRetry: Bool
  public let philosopherName: String
  public let participantOptionTitle: String
  public let opponentOptionTitle: String
  public let messages: [Message]
  public let aiNotice: String
  public let replyMinLength: Int
  public let replyMaxLength: Int

  public init(
    sessionID: Int,
    status: Status,
    round: Int,
    canReply: Bool,
    canRetry: Bool,
    philosopherName: String,
    participantOptionTitle: String,
    opponentOptionTitle: String,
    messages: [Message],
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
