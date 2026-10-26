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
}
