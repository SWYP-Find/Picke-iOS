//
//  ClassRepositoryImpl.swift
//  ClassDomain
//
//  Created by Picke on 10/11/26.
//

import APIEndpoint
import ClassDomainInterface
import Dependencies
import Foundation
import PickeNetwork

public final class ClassRepositoryImpl: ClassInterface {
  private static let unavailableMessage = "클래스 서버 API가 연결되지 않았습니다."
  @Dependency(\.networkClient) private var client

  public init() {}

  public func fetchMyClasses() async throws -> [ClassRoom] {
    do {
      let data = try await client.send(ClassroomService.myClasses, as: [ClassListItemDTO].self)
      return try data.map { try $0.toDomain() }
    } catch {
      throw Self.classError(error)
    }
  }

  public func fetchRecommendedBattles(filter: ClassTopicFilter) async throws -> [ClassBattleSummary] {
    guard (1 ... 3).contains(filter.categories.count), filter.keyword.count <= 50 else {
      throw ClassError.unknown("추천 조건을 확인해 주세요.")
    }
    do {
      let data = try await client.send(
        ClassBattleRecommendationService.recommendations(filter: filter),
        as: ClassBattleRecommendationDataDTO.self
      )
      return try data.items.map { try $0.toDomain() }
    } catch let error as PickeNetworkError {
      if case let .response(response) = error {
        throw ClassError.network(response.message ?? "배틀 추천을 불러오지 못했습니다.")
      }
      throw ClassError.from(error)
    }
  }

  public func createClass(_ creation: ClassCreation) async throws -> ClassRoom {
    do {
      let data = try await client.send(ClassroomService.create(creation), as: ClassDetailDataDTO.self)
      return try data.toDomain()
    } catch {
      throw Self.classError(error)
    }
  }

  public func fetchClass(id: Int) async throws -> ClassRoom {
    do {
      let data = try await client.send(ClassroomService.detail(id), as: ClassDetailDataDTO.self)
      return try data.toDomain()
    } catch {
      throw Self.classError(error)
    }
  }

  public func fetchClass(joinCode _: String) async throws -> ClassRoom {
    throw ClassError.unknown("참여 미리보기는 클래스 상세를 제공하지 않습니다.")
  }

  public func fetchClassPreview(joinCode: String) async throws -> ClassJoinPreview {
    do {
      let data = try await client.send(
        ClassroomService.joinPreview(joinCode),
        as: ClassJoinPreviewDataDTO.self
      )
      return try data.toDomain()
    } catch {
      throw Self.classError(error)
    }
  }

  public func joinClass(joinCode: String, nickname: String) async throws -> ClassRoom {
    do {
      let data = try await client.send(
        ClassroomService.join(code: joinCode, nickname: nickname),
        as: ClassDetailDataDTO.self
      )
      return try data.toDomain()
    } catch {
      throw Self.classError(error)
    }
  }

  public func updateDeadline(id: Int, deadline: Date) async throws -> ClassRoom {
    do {
      _ = try await client.send(
        ClassroomService.updateDeadline(id: id, deadline: deadline),
        as: PickeEmptyResponse.self
      )
      let data = try await client.send(ClassroomService.detail(id), as: ClassDetailDataDTO.self)
      return try data.toDomain()
    } catch {
      throw Self.classError(error)
    }
  }

  public func deleteClass(id: Int) async throws {
    do {
      _ = try await client.send(ClassroomService.delete(id), as: PickeEmptyResponse.self)
    } catch {
      throw Self.classError(error)
    }
  }

  public func leaveClass(id: Int) async throws {
    do {
      _ = try await client.send(ClassroomService.leave(id), as: PickeEmptyResponse.self)
    } catch {
      throw Self.classError(error)
    }
  }

  public func fetchReport(roomID _: Int) async throws -> ClassReport? {
    throw ClassError.network(Self.unavailableMessage)
  }

  public func fetchOwnerDashboard(roomID _: Int) async throws -> ClassOwnerDashboardData? {
    throw ClassError.network(Self.unavailableMessage)
  }

  private static func classError(_ error: Error) -> ClassError {
    guard let networkError = error as? PickeNetworkError else { return ClassError.from(error) }
    guard case let .response(response) = networkError else { return ClassError.from(networkError) }
    return ClassErrorMapper.map(
      code: response.code,
      message: response.message,
      fallback: "클래스 요청을 처리하지 못했습니다."
    )
  }
}

extension ClassRepositoryImpl {
  public func fetchBattle(classID: Int) async throws -> ClassBattleSession {
    do {
      let payload = try await client.send(ClassBattleService.detail(classID: classID), as: ClassBattleSessionDTO.self)
      return try payload.toDomain()
    } catch { throw Self.battleError(error) }
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
    } catch { throw Self.battleError(error) }
  }

  public func completeTTS(classID: Int) async throws {
    do {
      _ = try await client.send(
        ClassBattleService.ttsComplete(classID: classID),
        as: PickeEmptyResponse.self
      )
    } catch { throw Self.battleError(error) }
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
    } catch { throw Self.battleError(error) }
  }

  public func fetchMyVotes(classID: Int) async throws -> ClassVoteHistory {
    do {
      let payload = try await client.send(ClassBattleService.myVotes(classID: classID), as: ClassVoteHistoryDTO.self)
      return try payload.toDomain()
    } catch { throw Self.battleError(error) }
  }

  public func fetchVoteStats(classID: Int) async throws -> ClassVoteStats {
    do {
      let payload = try await client.send(ClassBattleService.voteStats(classID: classID), as: ClassVoteStatsDTO.self)
      return try payload.toDomain()
    } catch { throw Self.battleError(error) }
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
    } catch { throw Self.battleError(error) }
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
    } catch { throw Self.battleError(error) }
  }

  public func fetchMyPerspectives(classID: Int) async throws -> [ClassPerspectiveItem] {
    do {
      let payload = try await client.send(
        ClassBattleService.myPerspectives(classID: classID),
        as: [ClassPerspectiveItemDTO].self
      )
      return try payload.map { try $0.toDomain() }
    } catch { throw Self.battleError(error) }
  }

  private static func battleError(_ error: Error) -> ClassBattleError {
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

extension ClassRepositoryImpl {
  public func fetchMembers(classID: Int) async throws -> ClassMemberList {
    do {
      let data = try await client.send(
        ClassMemberService.members(classID: classID),
        as: [ClassMemberDTO].self
      )
      return try ClassMemberDTO.toMemberList(data)
    } catch {
      throw Self.memberError(error)
    }
  }

  public func updateMyDisplayName(classID: Int, name: String) async throws -> ClassMember {
    do {
      let data = try await client.send(
        ClassMemberService.updateMyName(classID: classID, name: name),
        as: ClassMemberDTO.self
      )
      return data.toDomain()
    } catch {
      throw Self.memberError(error)
    }
  }

  public func removeMember(classID: Int, memberID: Int) async throws {
    do {
      _ = try await client.send(
        ClassMemberService.remove(classID: classID, memberID: memberID),
        as: PickeEmptyResponse.self
      )
    } catch {
      throw Self.memberError(error)
    }
  }

  private static func memberError(_ error: Error) -> ClassError {
    guard let networkError = error as? PickeNetworkError else { return ClassError.from(error) }
    guard case let .response(response) = networkError else { return ClassError.from(networkError) }
    return ClassErrorMapper.map(
      code: response.code,
      message: response.message,
      fallback: "멤버 요청을 처리하지 못했어요."
    )
  }
}

extension ClassRepositoryImpl {
  public func previewTicket(code: String) async throws -> ClassTicketPreview {
    do {
      let payload = try await client.send(ClassTicketService.preview(code: code), as: ClassTicketPreviewDTO.self)
      return try payload.toDomain()
    } catch {
      throw Self.ticketError(error)
    }
  }

  public func registerTicket(code: String) async throws -> ClassTicket {
    do {
      let payload = try await client.send(ClassTicketService.register(code: code), as: ClassTicketDTO.self)
      return try payload.toDomain()
    } catch {
      throw Self.ticketError(error)
    }
  }

  public func fetchMyTicket() async throws -> ClassTicket {
    do {
      let payload = try await client.send(ClassTicketService.me, as: ClassTicketDTO.self)
      return try payload.toDomain()
    } catch {
      throw Self.ticketError(error)
    }
  }

  static func ticketError(_ error: Error) -> ClassTicketError {
    if let error = error as? ClassTicketError { return error }
    if let error = error as? PickeNetworkError {
      if case let .response(response) = error {
        switch response.code {
        case "COMMON_400", "TICKET_404_CODE": return .invalidCode
        case "TICKET_409_REVOKED": return .revoked
        case "TICKET_409_REG_EXP": return .registrationExpired
        case "TICKET_409_CLAIMED": return .claimed
        case "TICKET_409_ACTIVE": return .activeTicket
        case "TICKET_404": return .notFound
        default: return .network(response.message ?? "이용권 정보를 불러오지 못했어요.")
        }
      }
    }
    return .network(error.localizedDescription)
  }
}

extension ClassRepositoryImpl {
  public func fetchResult(roomID: Int) async throws -> ClassResult {
    do {
      let payload = try await client.send(ClassResultService.result(roomID), as: ClassResultDTO.self)
      return try payload.toDomain()
    } catch let error as PickeNetworkError {
      if case let .response(response) = error {
        throw Self.resultError(code: response.code, message: response.message)
      }
      throw ClassError.from(error)
    } catch {
      throw ClassError.from(error)
    }
  }

  public func fetchPersonalResult(roomID: Int) async throws -> ClassAIPersonalFeedback {
    do {
      let payload = try await client.send(ClassResultService.myReport(roomID), as: ClassPersonalReportDTO.self)
      return try payload.toDomain()
    } catch {
      throw Self.feedbackError(error)
    }
  }

  public func fetchInsight(roomID: Int) async throws -> ClassAIInsight {
    do {
      let payload = try await client.send(ClassResultService.insight(roomID), as: ClassInsightDTO.self)
      return try payload.toDomain()
    } catch {
      throw Self.feedbackError(error)
    }
  }

  public func retryInsight(roomID: Int) async throws {
    do {
      let payload = try await client.send(ClassResultService.retryInsight(roomID), as: ClassInsightRetryDTO.self)
      guard payload.state == "PENDING" else { throw ClassAIFeedbackError.generationFailed }
    } catch {
      throw Self.feedbackError(error)
    }
  }

  static func resultError(
    code: String?,
    message: String?
  ) -> ClassError {
    switch code {
    case "CLASS_409_RESULT_EXPIRED": return .resultExpired
    case "CLASS_403_MEMBER", "CLASS_403_OWNER": return .accessDenied
    default: return .network(message ?? "클래스 결과를 불러오지 못했어요.")
    }
  }

  static func feedbackError(code: String?) -> ClassAIFeedbackError {
    switch code {
    case "CLASS_409_REPORT_RETRY": return .generationFailed
    case "CLASS_409_RESULT_EXPIRED": return .resultExpired
    case "CLASS_403_MEMBER", "CLASS_403_OWNER": return .accessDenied
    default: return .temporarilyUnavailable
    }
  }

  static func feedbackError(_ error: Error) -> ClassAIFeedbackError {
    if let mapped = error as? ClassAIFeedbackError { return mapped }
    if error is DecodingError { return .invalidResponse }
    if let networkError = error as? PickeNetworkError {
      switch networkError {
      case .decoding: return .invalidResponse
      case let .response(response): return feedbackError(code: response.code)
      default: break
      }
    }
    return .temporarilyUnavailable
  }
}

extension ClassRepositoryImpl {
  public func fetchDebate(classID: Int) async throws -> ClassDebate {
    try await debate(.fetch(classID))
  }

  public func startDebate(classID: Int) async throws -> ClassDebate {
    try await debate(.start(classID))
  }

  public func retryDebate(classID: Int) async throws -> ClassDebate {
    try await debate(.retry(classID))
  }

  public func submitDebateReply(
    classID: Int,
    round: Int,
    content: String,
    requestKey: UUID
  ) async throws -> ClassDebate {
    try await debate(.submitReply(classID: classID, round: round, content: content, requestKey: requestKey))
  }

  private func debate(_ service: ClassDebateService) async throws -> ClassDebate {
    do {
      let payload = try await client.send(service, as: ClassDebateDTO.self)
      return try payload.toDomain()
    } catch let error as PickeNetworkError {
      if case let .response(response) = error {
        switch response.code {
        case "CLASS_404_DEBATE": throw ClassAIChatError.noSession
        case "CLASS_400_DEBATE_REPLY": throw ClassAIChatError.contentRejected
        case "CLASS_409_DEBATE_STATE", "CLASS_409_DEBATE_ROUND", "CLASS_409_DEBATE_RETRY":
          throw ClassAIChatError.temporarilyUnavailable
        default: throw ClassAIChatError.unexpectedFailure
        }
      }
      throw ClassAIChatError.temporarilyUnavailable
    }
  }

}

extension ClassRepositoryImpl {
  public func createTopicDraft(filter: ClassTopicFilter) async throws -> ClassTopicDraft {
    try await sendTopicDraft(ClassTopicDraftService.create(filter), as: ClassTopicDraftDTO.self).toDomain()
  }

  public func fetchTopicDraft(id: Int) async throws -> ClassTopicDraft {
    try await sendTopicDraft(ClassTopicDraftService.detail(id), as: ClassTopicDraftDTO.self).toDomain()
  }

  public func suggestTopicDraft(id: Int, filter: ClassTopicFilter?) async throws -> ClassTopicDraft {
    try await sendTopicDraft(ClassTopicDraftService.suggest(id, filter), as: ClassTopicDraftDTO.self).toDomain()
  }

  public func selectTopicDraft(draftID: Int, batchNo: Int, candidateID: Int) async throws -> ClassTopicVersion {
    try await sendTopicDraft(
      ClassTopicDraftService.select(draftID: draftID, batchNo: batchNo, candidateID: candidateID),
      as: ClassTopicVersionDTO.self
    ).toDomain()
  }

  public func validateTopicDraft(draftID: Int, baseVersionID: Int, candidate: ClassTopicCandidate) async throws -> ClassTopicValidation {
    try await sendTopicDraft(
      ClassTopicDraftService.validate(draftID: draftID, baseVersionID: baseVersionID, candidate: candidate),
      as: ClassTopicValidationDTO.self
    ).toDomain()
  }

  private func sendTopicDraft<T: Decodable & Sendable>(
    _ request: some PickeDataRequest,
    as type: T.Type
  ) async throws -> T {
    do {
      return try await client.send(request, as: type)
    } catch let error as PickeNetworkError {
      if case let .response(response) = error {
        throw ClassError.network(response.message ?? "AI 주제 요청을 처리하지 못했어요.")
      }
      throw ClassError.from(error)
    } catch {
      throw ClassError.from(error)
    }
  }
}

extension ClassRepositoryImpl {
  public func startAIChat(_ id: UUID, _ context: ClassAIChatContext) async throws {
    #if canImport(FoundationModels)
      if #available(iOS 26.0, *) {
        try await ClassAIChatFoundationEngine.shared.start(id: id, context: context)
        return
      }
    #endif
    throw ClassAIChatError.unavailable
  }

  public func respondAIChat(_ id: UUID, _ text: String, isFinalRound: Bool) async throws -> String {
    #if canImport(FoundationModels)
      if #available(iOS 26.0, *) {
        return try await ClassAIChatFoundationEngine.shared.respond(
          id: id,
          text: text,
          isFinalRound: isFinalRound
        )
      }
    #endif
    throw ClassAIChatError.unavailable
  }

  public func endAIChat(_ id: UUID) async {
    #if canImport(FoundationModels)
      if #available(iOS 26.0, *) {
        await ClassAIChatFoundationEngine.shared.end(id: id)
      }
    #endif
  }

  public func generateAIFeedback(context: ClassAIFeedbackContext) async throws -> ClassAIFeedbackResult {
    #if canImport(FoundationModels)
      if #available(iOS 26.0, *) {
        return try await ClassAIFeedbackFoundationEngine.generate(context: context)
      }
    #endif
    throw ClassAIFeedbackError.deviceNotEligible
  }
}
