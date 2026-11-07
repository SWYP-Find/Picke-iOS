import ClassDomainInterface
import Foundation
import PickeCoreUtility

extension ClassVoteReceiptDTO {
  func toDomain() throws -> ClassVoteReceipt {
    guard let status = ClassBattleStep(rawValue: status) else {
      throw ClassBattleError.invalidResponse
    }
    return ClassVoteReceipt(voteID: voteId, status: status)
  }
}

extension ClassVoteHistoryDTO.Choice {
  func toDomain() -> ClassVoteChoice {
    ClassVoteChoice(optionID: optionId, label: label, title: title)
  }
}

extension ClassMidVoteDTO {
  func toDomain() -> ClassMidVoteChoice {
    ClassMidVoteChoice(
      checkpointID: checkpointId,
      optionID: optionId,
      label: label
    )
  }
}

extension ClassVoteHistoryDTO {
  func toDomain() throws -> ClassVoteHistory {
    guard let status = ClassBattleStep(rawValue: status) else {
      throw ClassBattleError.invalidResponse
    }
    return ClassVoteHistory(
      battleTitle: battleTitle,
      preVote: preVote.toDomain(),
      midVotes: midVotes?.map { $0.toDomain() } ?? [],
      postVote: postVote?.toDomain(),
      status: status,
      opinionChanged: opinionChanged
    )
  }
}

extension ClassVoteStatsDTO.Option {
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

extension ClassVoteStatsDTO {
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
