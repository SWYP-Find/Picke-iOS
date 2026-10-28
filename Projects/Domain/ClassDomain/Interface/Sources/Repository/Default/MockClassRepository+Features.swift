import Foundation

public extension MockClassRepository {
  public func fetchBattle(classID: Int) async throws -> ClassBattleSession {
    throw ClassError.unknown("모의 클래스 기능이 설정되지 않았습니다: fetchBattle")
  }

  public func submitPreVote(classID: Int, optionID: Int) async throws -> ClassVoteReceipt {
    throw ClassError.unknown("모의 클래스 기능이 설정되지 않았습니다: submitPreVote")
  }

  public func submitMidVote(
    classID: Int,
    checkpointID: Int,
    optionID: Int
  ) async throws -> ClassVoteReceipt {
    throw ClassError.unknown("모의 클래스 기능이 설정되지 않았습니다: submitMidVote")
  }

  public func completeTTS(classID: Int) async throws {
    throw ClassError.unknown("모의 클래스 기능이 설정되지 않았습니다: completeTTS")
  }

  public func submitPostVote(classID: Int, optionID: Int) async throws -> ClassVoteReceipt {
    throw ClassError.unknown("모의 클래스 기능이 설정되지 않았습니다: submitPostVote")
  }

  public func fetchMyVotes(classID: Int) async throws -> ClassVoteHistory {
    throw ClassError.unknown("모의 클래스 기능이 설정되지 않았습니다: fetchMyVotes")
  }

  public func fetchVoteStats(classID: Int) async throws -> ClassVoteStats {
    throw ClassError.unknown("모의 클래스 기능이 설정되지 않았습니다: fetchVoteStats")
  }

  public func publishPerspective(classID: Int, content: String) async throws -> ClassPerspectiveReceipt {
    throw ClassError.unknown("모의 클래스 기능이 설정되지 않았습니다: publishPerspective")
  }

  public func fetchPerspectives(
    classID: Int,
    cursor: String?,
    size: Int?,
    optionID: Int?,
    sort: String?
  ) async throws -> ClassPerspectivePage {
    throw ClassError.unknown("모의 클래스 기능이 설정되지 않았습니다: fetchPerspectives")
  }

  public func fetchMyPerspectives(classID: Int) async throws -> [ClassPerspectiveItem] {
    throw ClassError.unknown("모의 클래스 기능이 설정되지 않았습니다: fetchMyPerspectives")
  }

  public func fetchMembers(classID: Int) async throws -> ClassMemberList {
    let members = try await fetchMembers(roomID: classID)
    let currentID = try await currentMemberID(roomID: classID)
    return ClassMemberList(members: members, currentMemberID: currentID)
  }

  public func updateMyDisplayName(classID: Int, name: String) async throws -> ClassMember {
    let currentID = try await currentMemberID(roomID: classID)
    return try await updateDisplayName(
      roomID: classID,
      memberID: currentID,
      currentMemberID: currentID,
      name: name
    )
  }

  public func removeMember(classID: Int, memberID: Int) async throws {
    let currentID = try await currentMemberID(roomID: classID)
    _ = try await removeMember(roomID: classID, memberID: memberID, currentMemberID: currentID)
  }

  public func fetchDebate(classID: Int) async throws -> ClassDebate {
    throw ClassError.unknown("모의 클래스 기능이 설정되지 않았습니다: fetchDebate")
  }

  public func startDebate(classID: Int) async throws -> ClassDebate {
    throw ClassError.unknown("모의 클래스 기능이 설정되지 않았습니다: startDebate")
  }

  public func submitDebateReply(
    classID: Int,
    round: Int,
    content: String,
    requestKey: UUID
  ) async throws -> ClassDebate {
    throw ClassError.unknown("모의 클래스 기능이 설정되지 않았습니다: submitDebateReply")
  }

  public func retryDebate(classID: Int) async throws -> ClassDebate {
    throw ClassError.unknown("모의 클래스 기능이 설정되지 않았습니다: retryDebate")
  }

  public func previewTicket(code: String) async throws -> ClassTicketPreview {
    throw ClassError.unknown("모의 클래스 기능이 설정되지 않았습니다: previewTicket")
  }

  public func registerTicket(code: String) async throws -> ClassTicket {
    throw ClassError.unknown("모의 클래스 기능이 설정되지 않았습니다: registerTicket")
  }

  public func fetchMyTicket() async throws -> ClassTicket {
    throw ClassError.unknown("모의 클래스 기능이 설정되지 않았습니다: fetchMyTicket")
  }

  public func fetchResult(roomID: Int) async throws -> ClassResult {
    throw ClassError.unknown("모의 클래스 기능이 설정되지 않았습니다: fetchResult")
  }

  public func fetchPersonalResult(roomID: Int) async throws -> ClassAIPersonalFeedback {
    throw ClassError.unknown("모의 클래스 기능이 설정되지 않았습니다: fetchPersonalResult")
  }

  public func fetchInsight(roomID: Int) async throws -> ClassAIInsight {
    throw ClassError.unknown("모의 클래스 기능이 설정되지 않았습니다: fetchInsight")
  }

  public func retryInsight(roomID: Int) async throws {
    throw ClassError.unknown("모의 클래스 기능이 설정되지 않았습니다: retryInsight")
  }

  public func createTopicDraft(filter: ClassTopicFilter) async throws -> ClassTopicDraft {
    throw ClassError.unknown("모의 클래스 기능이 설정되지 않았습니다: createTopicDraft")
  }

  public func fetchTopicDraft(id: Int) async throws -> ClassTopicDraft {
    throw ClassError.unknown("모의 클래스 기능이 설정되지 않았습니다: fetchTopicDraft")
  }

  public func suggestTopicDraft(id: Int, filter: ClassTopicFilter?) async throws -> ClassTopicDraft {
    throw ClassError.unknown("모의 클래스 기능이 설정되지 않았습니다: suggestTopicDraft")
  }

  public func selectTopicDraft(draftID: Int, batchNo: Int, candidateID: Int) async throws -> ClassTopicVersion {
    throw ClassError.unknown("모의 클래스 기능이 설정되지 않았습니다: selectTopicDraft")
  }

  public func validateTopicDraft(
    draftID: Int,
    baseVersionID: Int,
    candidate: ClassTopicCandidate
  ) async throws -> ClassTopicValidation {
    throw ClassError.unknown("모의 클래스 기능이 설정되지 않았습니다: validateTopicDraft")
  }

  public func startAIChat(_ id: UUID, _ context: ClassAIChatContext) async throws {
    throw ClassError.unknown("모의 클래스 기능이 설정되지 않았습니다: startAIChat")
  }

  public func respondAIChat(_ id: UUID, _ text: String, isFinalRound: Bool) async throws -> String {
    throw ClassError.unknown("모의 클래스 기능이 설정되지 않았습니다: respondAIChat")
  }

  public func endAIChat(_ id: UUID) async {
    return
  }

  public func generateAIFeedback(context: ClassAIFeedbackContext) async throws -> ClassAIFeedbackResult {
    if let feedbackHandler {
      return try await feedbackHandler(context)
    }
    throw ClassError.unknown("모의 클래스 기능이 설정되지 않았습니다: generateAIFeedback")
  }
}
