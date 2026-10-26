//
//  ClassInterface.swift
//  ClassDomainInterface
//
//  Created by Picke on 10/11/26.
//

import ComposableArchitecture
import Foundation

public protocol ClassInterface: Sendable {
  func fetchMyClasses() async throws -> [ClassRoom]
  func fetchRecommendedBattles(filter: ClassTopicFilter) async throws -> [ClassBattleSummary]
  func createClass(_ creation: ClassCreation) async throws -> ClassRoom
  func fetchClass(id: Int) async throws -> ClassRoom
  func fetchClass(joinCode: String) async throws -> ClassRoom
  func fetchClassPreview(joinCode: String) async throws -> ClassJoinPreview
  func joinClass(joinCode: String, nickname: String) async throws -> ClassRoom
  func updateDeadline(id: Int, deadline: Date) async throws -> ClassRoom
  func deleteClass(id: Int) async throws
  func leaveClass(id: Int) async throws
  func fetchReport(roomID: Int) async throws -> ClassReport?
  func fetchOwnerDashboard(roomID: Int) async throws -> ClassOwnerDashboardData?
  func fetchBattle(classID: Int) async throws -> ClassBattleSession
  func submitPreVote(classID: Int, optionID: Int) async throws -> ClassVoteReceipt
  func completeTTS(classID: Int) async throws
  func submitPostVote(classID: Int, optionID: Int) async throws -> ClassVoteReceipt
  func fetchMyVotes(classID: Int) async throws -> ClassVoteHistory
  func fetchVoteStats(classID: Int) async throws -> ClassVoteStats
  func publishPerspective(classID: Int, content: String) async throws -> ClassPerspectiveReceipt
  func fetchPerspectives(
    classID: Int,
    cursor: String?,
    size: Int?,
    optionID: Int?,
    sort: String?
  ) async throws -> ClassPerspectivePage
  func fetchMyPerspectives(classID: Int) async throws -> [ClassPerspectiveItem]
  func fetchMembers(classID: Int) async throws -> ClassMemberList
  func updateMyDisplayName(classID: Int, name: String) async throws -> ClassMember
  func removeMember(classID: Int, memberID: Int) async throws
  func fetchDebate(classID: Int) async throws -> ClassDebate
  func startDebate(classID: Int) async throws -> ClassDebate
  func submitDebateReply(
    classID: Int,
    round: Int,
    content: String,
    requestKey: UUID
  ) async throws -> ClassDebate
  func retryDebate(classID: Int) async throws -> ClassDebate
  func previewTicket(code: String) async throws -> ClassTicketPreview
  func registerTicket(code: String) async throws -> ClassTicket
  func fetchMyTicket() async throws -> ClassTicket
  func fetchResult(roomID: Int) async throws -> ClassResult
  func fetchPersonalResult(roomID: Int) async throws -> ClassAIPersonalFeedback
  func fetchInsight(roomID: Int) async throws -> ClassAIInsight
  func retryInsight(roomID: Int) async throws
  func createTopicDraft(filter: ClassTopicFilter) async throws -> ClassTopicDraft
  func fetchTopicDraft(id: Int) async throws -> ClassTopicDraft
  func suggestTopicDraft(id: Int, filter: ClassTopicFilter?) async throws -> ClassTopicDraft
  func selectTopicDraft(draftID: Int, batchNo: Int, candidateID: Int) async throws -> ClassTopicVersion
  func validateTopicDraft(
    draftID: Int,
    baseVersionID: Int,
    candidate: ClassTopicCandidate
  ) async throws -> ClassTopicValidation
  func startAIChat(_ id: UUID, _ context: ClassAIChatContext) async throws
  func respondAIChat(_ id: UUID, _ text: String, isFinalRound: Bool) async throws -> String
  func endAIChat(_ id: UUID) async
  func generateAIFeedback(context: ClassAIFeedbackContext) async throws -> ClassAIFeedbackResult
}

public extension ClassInterface {
  func fetchClassPreview(joinCode: String) async throws -> ClassJoinPreview {
    let room = try await fetchClass(joinCode: joinCode)
    return ClassJoinPreview(room: room)
  }
}

public enum ClassRepositoryDependency: TestDependencyKey {
  public static var testValue: any ClassInterface {
    MockClassRepository()
  }
}

public enum ClassUseCaseDependency: TestDependencyKey {
  public static var testValue: any ClassInterface {
    MockClassRepository()
  }
}

public enum ClassMockRepositoryDependency: TestDependencyKey {
  public static var testValue: MockClassRepository? {
    nil
  }
}

public extension DependencyValues {
  var classRepository: any ClassInterface {
    get { self[ClassRepositoryDependency.self] }
    set { self[ClassRepositoryDependency.self] = newValue }
  }

  var classUseCase: any ClassInterface {
    get { self[ClassUseCaseDependency.self] }
    set { self[ClassUseCaseDependency.self] = newValue }
  }

  var classMockRepository: MockClassRepository? {
    get { self[ClassMockRepositoryDependency.self] }
    set { self[ClassMockRepositoryDependency.self] = newValue }
  }
}
