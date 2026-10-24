import ClassDomainInterface

struct ClassDebateDTO: Decodable, Sendable {
  struct Philosopher: Decodable, Sendable {
    let name: String
  }

  struct Option: Decodable, Sendable {
    let title: String
  }

  struct Message: Decodable, Sendable {
    let messageId: Int
    let round: Int
    let speaker: String
    let content: String

    func toDomain() throws -> ClassDebateMessage {
      guard let speaker = ClassDebateSpeaker(rawValue: speaker) else {
        throw ClassAIChatError.invalidOutput
      }
      return ClassDebateMessage(
        id: messageId,
        round: round,
        speaker: speaker,
        content: content
      )
    }
  }

  let sessionId: Int
  let status: String
  let round: Int
  let canReply: Bool
  let canRetry: Bool
  let philosopher: Philosopher
  let participantOption: Option
  let opponentOption: Option
  let messages: [Message]
  let aiNotice: String
  let replyMinLength: Int
  let replyMaxLength: Int

  func toDomain() throws -> ClassDebate {
    guard let status = ClassDebateStatus(rawValue: status) else {
      throw ClassAIChatError.invalidOutput
    }
    return try ClassDebate(
      sessionID: sessionId,
      status: status,
      round: round,
      canReply: canReply,
      canRetry: canRetry,
      philosopherName: philosopher.name,
      participantOptionTitle: participantOption.title,
      opponentOptionTitle: opponentOption.title,
      messages: messages.map { try $0.toDomain() },
      aiNotice: aiNotice,
      replyMinLength: replyMinLength,
      replyMaxLength: replyMaxLength
    )
  }
}
