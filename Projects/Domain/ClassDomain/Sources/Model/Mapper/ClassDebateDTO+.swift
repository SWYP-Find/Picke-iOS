import ClassDomainInterface

extension ClassDebateDTO.Message {
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

extension ClassDebateDTO {
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
