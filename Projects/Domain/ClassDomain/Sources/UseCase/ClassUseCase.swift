//
//  ClassUseCase.swift
//  ClassDomain
//
//  Created by Picke on 10/11/26.
//

import ClassDomainInterface
import ComposableArchitecture
import Foundation

public struct ClassUseCaseImpl: ClassInterface {
  @Dependency(\.classRepository) private var repository

  public init() {}

  public func fetchMyClasses() async throws -> [ClassRoom] {
    try await repository.fetchMyClasses()
  }

  public func fetchRecommendedBattles(filter: ClassTopicFilter) async throws -> [ClassBattleSummary] {
    try await repository.fetchRecommendedBattles(filter: filter)
  }

  public func createClass(_ creation: ClassCreation) async throws -> ClassRoom {
    try await repository.createClass(creation)
  }

  public func fetchClass(id: Int) async throws -> ClassRoom {
    try await repository.fetchClass(id: id)
  }

  public func fetchClass(joinCode: String) async throws -> ClassRoom {
    try await repository.fetchClass(joinCode: joinCode)
  }

  public func fetchClassPreview(joinCode: String) async throws -> ClassJoinPreview {
    try await repository.fetchClassPreview(joinCode: joinCode)
  }

  public func joinClass(joinCode: String, nickname: String) async throws -> ClassRoom {
    try await repository.joinClass(joinCode: joinCode, nickname: nickname)
  }

  public func updateDeadline(id: Int, deadline: Date) async throws -> ClassRoom {
    try await repository.updateDeadline(id: id, deadline: deadline)
  }

  public func deleteClass(id: Int) async throws {
    try await repository.deleteClass(id: id)
  }

  public func leaveClass(id: Int) async throws {
    try await repository.leaveClass(id: id)
  }

  public func fetchReport(roomID: Int) async throws -> ClassReport? {
    try await repository.fetchReport(roomID: roomID)
  }

  public func fetchOwnerDashboard(roomID: Int) async throws -> ClassOwnerDashboardData? {
    try await repository.fetchOwnerDashboard(roomID: roomID)
  }
}

extension ClassUseCaseImpl {
  public func fetchBattle(classID: Int) async throws -> ClassBattleSession {
    try await repository.fetchBattle(classID: classID)
  }

  public func submitPreVote(classID: Int, optionID: Int) async throws -> ClassVoteReceipt {
    try await repository.submitPreVote(classID: classID, optionID: optionID)
  }

  public func completeTTS(classID: Int) async throws {
    try await repository.completeTTS(classID: classID)
  }

  public func submitPostVote(classID: Int, optionID: Int) async throws -> ClassVoteReceipt {
    try await repository.submitPostVote(classID: classID, optionID: optionID)
  }

  public func fetchMyVotes(classID: Int) async throws -> ClassVoteHistory {
    try await repository.fetchMyVotes(classID: classID)
  }

  public func fetchVoteStats(classID: Int) async throws -> ClassVoteStats {
    try await repository.fetchVoteStats(classID: classID)
  }

  public func publishPerspective(classID: Int, content: String) async throws -> ClassPerspectiveReceipt {
    try await repository.publishPerspective(classID: classID, content: content)
  }

  public func fetchPerspectives(
    classID: Int,
    cursor: String?,
    size: Int?,
    optionID: Int?,
    sort: String?
  ) async throws -> ClassPerspectivePage {
    try await repository.fetchPerspectives(
      classID: classID,
      cursor: cursor,
      size: size,
      optionID: optionID,
      sort: sort
    )
  }

  public func fetchMyPerspectives(classID: Int) async throws -> [ClassPerspectiveItem] {
    try await repository.fetchMyPerspectives(classID: classID)
  }

  public func fetchMembers(classID: Int) async throws -> ClassMemberList {
    try await repository.fetchMembers(classID: classID)
  }

  public func updateMyDisplayName(classID: Int, name: String) async throws -> ClassMember {
    try await repository.updateMyDisplayName(classID: classID, name: name)
  }

  public func removeMember(classID: Int, memberID: Int) async throws {
    try await repository.removeMember(classID: classID, memberID: memberID)
  }

  public func fetchDebate(classID: Int) async throws -> ClassDebate {
    try await repository.fetchDebate(classID: classID)
  }

  public func startDebate(classID: Int) async throws -> ClassDebate {
    try await repository.startDebate(classID: classID)
  }

  public func submitDebateReply(
    classID: Int,
    round: Int,
    content: String,
    requestKey: UUID
  ) async throws -> ClassDebate {
    try await repository.submitDebateReply(
      classID: classID,
      round: round,
      content: content,
      requestKey: requestKey
    )
  }

  public func retryDebate(classID: Int) async throws -> ClassDebate {
    try await repository.retryDebate(classID: classID)
  }

  public func previewTicket(code: String) async throws -> ClassTicketPreview {
    try await repository.previewTicket(code: code)
  }

  public func registerTicket(code: String) async throws -> ClassTicket {
    try await repository.registerTicket(code: code)
  }

  public func fetchMyTicket() async throws -> ClassTicket {
    try await repository.fetchMyTicket()
  }

  public func fetchResult(roomID: Int) async throws -> ClassResult {
    try await repository.fetchResult(roomID: roomID)
  }

  public func fetchPersonalResult(roomID: Int) async throws -> ClassAIPersonalFeedback {
    try await repository.fetchPersonalResult(roomID: roomID)
  }

  public func fetchInsight(roomID: Int) async throws -> ClassAIInsight {
    try await repository.fetchInsight(roomID: roomID)
  }

  public func retryInsight(roomID: Int) async throws {
    try await repository.retryInsight(roomID: roomID)
  }

  public func createTopicDraft(filter: ClassTopicFilter) async throws -> ClassTopicDraft {
    try await repository.createTopicDraft(filter: filter)
  }

  public func fetchTopicDraft(id: Int) async throws -> ClassTopicDraft {
    try await repository.fetchTopicDraft(id: id)
  }

  public func suggestTopicDraft(id: Int, filter: ClassTopicFilter?) async throws -> ClassTopicDraft {
    try await repository.suggestTopicDraft(id: id, filter: filter)
  }

  public func selectTopicDraft(draftID: Int, batchNo: Int, candidateID: Int) async throws -> ClassTopicVersion {
    try await repository.selectTopicDraft(draftID: draftID, batchNo: batchNo, candidateID: candidateID)
  }

  public func validateTopicDraft(
    draftID: Int,
    baseVersionID: Int,
    candidate: ClassTopicCandidate
  ) async throws -> ClassTopicValidation {
    try await repository.validateTopicDraft(
      draftID: draftID,
      baseVersionID: baseVersionID,
      candidate: candidate
    )
  }

  public func startAIChat(_ id: UUID, _ context: ClassAIChatContext) async throws {
    try await repository.startAIChat(id, context)
  }

  public func respondAIChat(_ id: UUID, _ text: String, isFinalRound: Bool) async throws -> String {
    try await repository.respondAIChat(id, text, isFinalRound: isFinalRound)
  }

  public func endAIChat(_ id: UUID) async {
    await repository.endAIChat(id)
  }

  public func generateAIFeedback(context: ClassAIFeedbackContext) async throws -> ClassAIFeedbackResult {
    try await repository.generateAIFeedback(context: context)
  }
}
