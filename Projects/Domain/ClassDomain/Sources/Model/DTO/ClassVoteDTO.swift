import ClassDomainInterface
import Foundation
import PickeCoreUtility

struct ClassVoteReceiptDTO: Decodable, Sendable {
  let voteId: Int
  let status: String
}

struct ClassMidVoteDTO: Decodable, Sendable {
  let checkpointId: Int
  let optionId: Int
  let label: String
}

struct ClassVoteHistoryDTO: Decodable, Sendable {
  struct Choice: Decodable, Sendable {
    let optionId: Int
    let label: String
    let title: String

  }

  let battleTitle: String
  let preVote: Choice
  let midVotes: [ClassMidVoteDTO]?
  let postVote: Choice?
  let status: String
  let opinionChanged: Bool?
}

struct ClassVoteStatsDTO: Decodable, Sendable {
  struct Option: Decodable, Sendable {
    let optionId: Int
    let title: String
    let imageUrl: String?
    let voteCount: Int
    let ratio: Double

  }

  let options: [Option]
  let totalCount: Int
  let updatedAt: String
}
