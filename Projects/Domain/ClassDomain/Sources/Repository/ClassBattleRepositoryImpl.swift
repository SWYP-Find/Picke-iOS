import ClassDomainInterface
import Dependencies
import Foundation
import PickeNetwork

public struct ClassBattleRepositoryImpl: ClassBattleInterface {
  @Dependency(\.networkClient) private var client

  public init() {}

  public func fetchBattle(classID: Int) async throws -> ClassBattleSession {
    do {
      let payload = try await client.send(ClassBattleService.detail(classID: classID), as: ClassBattleSessionDTO.self)
      return try payload.toDomain()
    } catch { throw Self.map(error) }
  }

  public func submitPreVote(
    classID: Int,
    optionID: Int
  ) async throws -> ClassVoteReceipt {
    do {
      let payload = try await client.send(
        ClassBattleService.preVote(classID: classID, optionID: optionID),
        as: ClassVoteReceiptDTO.self
      )
      return try payload.toDomain()
    } catch { throw Self.map(error) }
  }

  public func completeTTS(classID: Int) async throws {
    do {
      _ = try await client.send(
        ClassBattleService.ttsComplete(classID: classID),
        as: PickeEmptyResponse.self
      )
    } catch { throw Self.map(error) }
  }

  public func submitPostVote(
    classID: Int,
    optionID: Int
  ) async throws -> ClassVoteReceipt {
    do {
      let payload = try await client.send(
        ClassBattleService.postVote(classID: classID, optionID: optionID),
        as: ClassVoteReceiptDTO.self
      )
      return try payload.toDomain()
    } catch { throw Self.map(error) }
  }

  public func fetchMyVotes(classID: Int) async throws -> ClassVoteHistory {
    do {
      let payload = try await client.send(ClassBattleService.myVotes(classID: classID), as: ClassVoteHistoryDTO.self)
      return try payload.toDomain()
    } catch { throw Self.map(error) }
  }

  public func fetchVoteStats(classID: Int) async throws -> ClassVoteStats {
    do {
      let payload = try await client.send(ClassBattleService.voteStats(classID: classID), as: ClassVoteStatsDTO.self)
      return try payload.toDomain()
    } catch { throw Self.map(error) }
  }

  public func publishPerspective(
    classID: Int,
    content: String
  ) async throws -> ClassPerspectiveReceipt {
    do {
      let payload = try await client.send(
        ClassBattleService.publishPerspective(classID: classID, content: content),
        as: ClassPerspectiveReceiptDTO.self
      )
      return try payload.toDomain()
    } catch { throw Self.map(error) }
  }

  public func fetchPerspectives(
    classID: Int,
    cursor: String?,
    size: Int?,
    optionID: Int?,
    sort: String?
  ) async throws -> ClassPerspectivePage {
    do {
      let payload = try await client.send(
        ClassBattleService.perspectives(
          classID: classID,
          cursor: cursor,
          size: size,
          optionID: optionID,
          sort: sort
        ),
        as: ClassPerspectivePageDTO.self
      )
      return try payload.toDomain()
    } catch { throw Self.map(error) }
  }

  public func fetchMyPerspectives(classID: Int) async throws -> [ClassPerspectiveItem] {
    do {
      let payload = try await client.send(
        ClassBattleService.myPerspectives(classID: classID),
        as: [ClassPerspectiveItemDTO].self
      )
      return try payload.map { try $0.toDomain() }
    } catch { throw Self.map(error) }
  }

  private static func map(_ error: Error) -> ClassBattleError {
    if let error = error as? ClassBattleError { return error }
    if let error = error as? PickeNetworkError,
       case let .response(response) = error
    {
      switch response.code {
      case "CLASS_404": return .classNotFound
      case "CLASS_403_MEMBER": return .membershipRequired
      case "CLASS_409_TICKET_ENDED": return .ticketEnded
      case "CLASS_409_CLOSED": return .closed
      case "CLASS_409_PRE_VOTE_LOCKED": return .preVoteLocked
      case "BATTLE_OPT_404": return .invalidOption
      case "CLASS_409_TTS": return .ttsUnavailable
      case "VOTE_404": return .voteNotFound
      case "VOTE_409_PRE": return .preVoteRequired
      case "VOTE_409_SUB": return .alreadySubmitted
      case "CLASS_409_DEBATE_INCOMPLETE": return .debateIncomplete
      default: return .network(response.message ?? "클래스 배틀 요청을 처리하지 못했어요.")
      }
    }
    return .network(error.localizedDescription)
  }
}
