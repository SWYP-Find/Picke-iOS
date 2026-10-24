import ClassDomainInterface
import Foundation
import PickeCoreUtility

struct ClassVoteReceiptDTO: Decodable, Sendable {
  let voteId: Int
  let status: String

  func toDomain() throws -> ClassVoteReceipt {
    guard let status = ClassBattleStep(rawValue: status) else {
      throw ClassBattleError.invalidResponse
    }
    return ClassVoteReceipt(voteID: voteId, status: status)
  }
}

struct ClassVoteHistoryDTO: Decodable, Sendable {
  struct Choice: Decodable, Sendable {
    let optionId: Int
    let label: String
    let title: String

    func toDomain() -> ClassVoteChoice {
      ClassVoteChoice(optionID: optionId, label: label, title: title)
    }
  }

  let battleTitle: String
  let preVote: Choice
  let postVote: Choice?
  let status: String
  let opinionChanged: Bool?

  func toDomain() throws -> ClassVoteHistory {
    guard let status = ClassBattleStep(rawValue: status) else {
      throw ClassBattleError.invalidResponse
    }
    return ClassVoteHistory(
      battleTitle: battleTitle,
      preVote: preVote.toDomain(),
      postVote: postVote?.toDomain(),
      status: status,
      opinionChanged: opinionChanged
    )
  }
}

struct ClassVoteStatsDTO: Decodable, Sendable {
  struct Option: Decodable, Sendable {
    let optionId: Int
    let title: String
    let imageUrl: String?
    let voteCount: Int
    let ratio: Double

    func toDomain() -> ClassVoteStatsOption {
      ClassVoteStatsOption(
        id: optionId,
        title: title,
        imageURL: imageUrl.flatMap(URL.init(string:)),
        voteCount: voteCount,
        ratio: ratio
      )
    }
  }

  let options: [Option]
  let totalCount: Int
  let updatedAt: String

  func toDomain() throws -> ClassVoteStats {
    guard let updatedAt = ServerDateParser.parse(updatedAt) else {
      throw ClassBattleError.invalidResponse
    }
    return ClassVoteStats(
      options: options.map { $0.toDomain() },
      totalCount: totalCount,
      updatedAt: updatedAt
    )
  }
}
