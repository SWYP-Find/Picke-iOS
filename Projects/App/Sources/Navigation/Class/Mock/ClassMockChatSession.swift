//
//  ClassMockChatSession.swift
//  Picke
//
//  Created by Picke on 10/11/26.
//

import BattleDomainInterface
import ClassDomainInterface
import CommentDomainInterface
import Dependencies
import Foundation
import HomeDomainInterface
import PerspectiveDomainInterface
import PickeDesignKit

/// 클래스 사용자 흐름의 배틀 데이터를 앱 내부에만 보관한다.
/// 실제 배틀 ID와 충돌하지 않도록 클래스 ID를 음수 ID로 분리한다.
actor ClassMockChatSession: @preconcurrency BattleInterface, @preconcurrency PerspectiveInterface,
  @preconcurrency CommentInterface
{
  private struct Entry {
    var room: ClassRoom
    var preVoteOptionID: Int?
    var postVoteOptionID: Int?
    var perspectiveOptionID: Int?
    var perspectiveContent: String?
    var perspectiveLiked = false
    var comments: [Int: String] = [:]
  }

  private var entries: [Int: Entry] = [:]
  private var nextCommentID = -1
  private var closedBattleArtworkURL: URL?

  private func thumbnailURL(for battle: ClassBattleSummary) async -> URL? {
    if let thumbnailURL = battle.thumbnailURL {
      return thumbnailURL
    }
    guard battle.id == 101, battle.title == "촉법소년 연령을 낮춰야 할까?" else { return nil }
    if let closedBattleArtworkURL {
      return closedBattleArtworkURL
    }

    let imageData = await MainActor.run { PickeDesignKitAsset.classClosedBattle.image.pngData() }
    guard let imageData else { return nil }
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("picke-class-closed-battle.png")
    do {
      try imageData.write(to: url, options: .atomic)
      closedBattleArtworkURL = url
      return url
    } catch {
      return nil
    }
  }

  func register(room: ClassRoom) -> Int {
    let battleID = -1_000_000 - room.id
    if var entry = entries[battleID] {
      entry.room = room
      entries[battleID] = entry
    } else {
      UserDefaults.standard.removeObject(forKey: "picke.chatRoom.hasFinishedListening.\(battleID)")
      entries[battleID] = Entry(room: room)
    }
    return battleID
  }

  func hasChangedMind(battleID: Int) -> Bool {
    guard let value = entries[battleID],
          let preVoteOptionID = value.preVoteOptionID,
          let postVoteOptionID = value.postVoteOptionID
    else { return false }
    return preVoteOptionID != postVoteOptionID
  }

  func clear(roomID: Int) {
    let battleID = -1_000_000 - roomID
    entries[battleID] = nil
    UserDefaults.standard.removeObject(forKey: "picke.chatRoom.hasFinishedListening.\(battleID)")
  }

  private func entry(for battleID: Int) throws -> Entry {
    guard let entry = entries[battleID] else { throw BattleError.noData }
    return entry
  }

  private func battleID(for perspectiveID: Int) throws -> Int {
    let battleID = (perspectiveID + 1) / 10
    guard entries[battleID] != nil, perspectiveID == battleID * 10 - 1 else {
      throw PerspectiveError.noData
    }
    return battleID
  }

  private func option(
    for entry: Entry,
    id: Int
  ) -> BattlePerspectiveOption {
    let isA = id == 1
    return BattlePerspectiveOption(
      optionId: id,
      label: isA ? "A" : "B",
      title: isA ? entry.room.battle.optionATitle : entry.room.battle.optionBTitle,
      stance: isA ? entry.room.battle.philosopherA : entry.room.battle.philosopherB
    )
  }

  private func perspective(
    for entry: Entry,
    battleID: Int
  ) -> BattlePerspective? {
    guard let content = entry.perspectiveContent else { return nil }
    return BattlePerspective(
      perspectiveId: battleID * 10 - 1,
      user: BattlePerspectiveUser(
        userTag: "나",
        nickname: "나",
        characterType: "",
        characterImageUrl: nil
      ),
      option: option(for: entry, id: entry.perspectiveOptionID ?? entry.postVoteOptionID ?? entry.preVoteOptionID ?? 1),
      content: content,
      likeCount: entry.perspectiveLiked ? 1 : 0,
      commentCount: entry.comments.count,
      isLiked: entry.perspectiveLiked,
      isMyPerspective: true,
      createdAt: Date()
    )
  }

  func fetchTodayBattles() async throws -> TodayBattlePage {
    TodayBattlePage(items: [], totalCount: 0)
  }

  func fetchBattle(battleId: Int) async throws -> BattleDetail {
    let value = try entry(for: battleId)
    let room = value.room
    let battle = room.battle
    let thumbnailURL = await thumbnailURL(for: battle)
    let votedOptionID = value.postVoteOptionID ?? value.preVoteOptionID
    let options = [
      BattleOption(
        optionId: 1,
        label: "A",
        title: battle.optionATitle,
        stance: battle.optionATitle,
        representative: battle.philosopherA,
        imageUrl: battle.philosopherAImageURL?.absoluteString ?? "",
        tags: []
      ),
      BattleOption(
        optionId: 2,
        label: "B",
        title: battle.optionBTitle,
        stance: battle.optionBTitle,
        representative: battle.philosopherB,
        imageUrl: battle.philosopherBImageURL?.absoluteString ?? "",
        tags: []
      ),
    ]
    return BattleDetail(
      battleInfo: BattleInfo(
        battleId: battleId,
        title: battle.title,
        summary: battle.summary,
        thumbnailUrl: thumbnailURL?.absoluteString ?? "",
        viewCount: battle.viewCount,
        participantsCount: room.memberCount,
        audioDuration: battle.audioDuration,
        tags: [],
        options: options
      ),
      description: battle.summary,
      shareUrl: "",
      userVoteStatus: votedOptionID == 1 ? .pro : votedOptionID == 2 ? .con : .none,
      currentStep: value.postVoteOptionID != nil ? .completed : value.preVoteOptionID != nil ? .listening : .preVote,
      categoryTags: [BattleTag(tagId: battle.id, name: battle.categoryDisplayTitle, type: .category)],
      philosopherTags: [],
      valueTags: []
    )
  }

  func submitPreVote(
    battleId: Int,
    optionId: Int
  ) async throws -> PreVoteResult {
    guard optionId == 1 || optionId == 2 else { throw BattleError.noData }
    var value = try entry(for: battleId)
    let status: PreVoteResultStatus = value.preVoteOptionID == nil ? .created : .updated
    value.preVoteOptionID = optionId
    entries[battleId] = value
    return PreVoteResult(voteId: battleId * 10 - 2, status: status)
  }

  func submitPostVote(
    battleId: Int,
    optionId: Int
  ) async throws -> PreVoteResult {
    guard optionId == 1 || optionId == 2 else { throw BattleError.noData }
    var value = try entry(for: battleId)
    guard value.postVoteOptionID == nil else {
      throw BattleError.backendError("이미 최종투표를 완료했어요.")
    }
    value.postVoteOptionID = optionId
    entries[battleId] = value
    return PreVoteResult(voteId: battleId * 10 - 3, status: .created)
  }

  func fetchScenario(battleId: Int) async throws -> BattleScenario {
    let battle = try entry(for: battleId).room.battle
    return BattleScenario(
      battleId: battleId,
      title: battle.title,
      philosophers: [
        ScenarioPhilosopher(label: "A", name: battle.philosopherA, stance: battle.optionATitle, imageUrl: ""),
        ScenarioPhilosopher(label: "B", name: battle.philosopherB, stance: battle.optionBTitle, imageUrl: ""),
      ],
      isInteractive: false,
      startNodeId: 1,
      recommendedPathKey: .common,
      audios: [RecommendedPathKey.common.rawValue: "picke-class-mock://battle/\(battleId)"],
      nodes: [
        ScenarioNode(
          nodeId: 1,
          nodeName: "클래스 토론",
          audioDuration: 8,
          autoNextNodeId: nil,
          scripts: [
            ScenarioScript(
              scriptId: 1,
              startTimeMs: 0,
              speakerType: .narrator,
              speakerName: "Pické",
              text: battle.summary
            ),
            ScenarioScript(
              scriptId: 2,
              startTimeMs: 2000,
              speakerType: .a,
              speakerName: battle.philosopherA,
              text: battle.optionATitle
            ),
            ScenarioScript(
              scriptId: 3,
              startTimeMs: 4000,
              speakerType: .b,
              speakerName: battle.philosopherB,
              text: battle.optionBTitle
            ),
          ],
          interactiveOptions: []
        ),
      ]
    )
  }

  func fetchVoteStats(battleId: Int) async throws -> BattleVoteStats {
    let value = try entry(for: battleId)
    let battle = value.room.battle
    let voteOptionID = value.postVoteOptionID ?? value.preVoteOptionID
    let aCount = 17 + (voteOptionID == 1 ? 1 : 0)
    let bCount = 15 + (voteOptionID == 2 ? 1 : 0)
    let total = aCount + bCount
    return BattleVoteStats(
      options: [
        BattleVoteStatsOption(
          optionId: 1,
          label: "A",
          title: battle.optionATitle,
          isCorrect: false,
          voteCount: aCount,
          ratio: Double(aCount) / Double(total),
          stance: battle.philosopherA,
          imageUrl: nil
        ),
        BattleVoteStatsOption(
          optionId: 2,
          label: "B",
          title: battle.optionBTitle,
          isCorrect: false,
          voteCount: bCount,
          ratio: Double(bCount) / Double(total),
          stance: battle.philosopherB,
          imageUrl: nil
        ),
      ],
      totalCount: total,
      updatedAt: Date()
    )
  }

  func fetchPerspectives(
    battleId: Int,
    cursor _: String?,
    size _: Int?,
    optionId: Int?,
    sort _: BattlePerspectiveSort?
  ) async throws -> BattlePerspectivePage {
    let value = try entry(for: battleId)
    let items = perspective(for: value, battleID: battleId).map { item in
      optionId == nil || optionId == item.option.optionId ? [item] : []
    } ?? []
    return BattlePerspectivePage(items: items, nextCursor: nil, hasNext: false)
  }

  func createPerspective(
    battleId: Int,
    content: String,
    optionId: Int?
  ) async throws -> BattlePerspective? {
    var value = try entry(for: battleId)
    value.perspectiveContent = content
    value.perspectiveOptionID = value.postVoteOptionID ?? value.preVoteOptionID ?? optionId
    entries[battleId] = value
    return perspective(for: value, battleID: battleId)
  }

  func fetchMyPerspective(battleId: Int) async throws -> BattlePerspective? {
    try perspective(for: entry(for: battleId), battleID: battleId)
  }

  func fetchRecommendedBattles(battleId _: Int) async throws -> RecommendedBattlePage {
    RecommendedBattlePage(items: [], nextCursor: nil, hasNext: false)
  }

  nonisolated func proposeBattle(_ draft: BattleProposalDraft) async throws -> BattleProposal {
    try await MockBattleRepository().proposeBattle(draft)
  }

  func fetchPerspective(perspectiveId: Int) async throws -> BattlePerspective {
    let id = try battleID(for: perspectiveId)
    guard let result = try perspective(for: entry(for: id), battleID: id) else {
      throw PerspectiveError.noData
    }
    return result
  }

  func fetchLabeledComments(
    perspectiveId: Int,
    cursor _: String?,
    size _: Int?
  ) async throws -> PerspectiveCommentPage {
    let id = try battleID(for: perspectiveId)
    let value = try entry(for: id)
    let items = value.comments.sorted(by: { $0.key > $1.key }).map { comment in
      PerspectiveComment(
        commentId: comment.key,
        user: PerspectiveCommentUser(userTag: "나", nickname: "나", characterType: "", characterImageUrl: nil),
        stance: option(
          for: value,
          id: value.perspectiveOptionID ?? value.postVoteOptionID ?? value.preVoteOptionID ?? 1
        ).title,
        content: comment.value,
        likeCount: 0,
        isLiked: false,
        isMine: true,
        createdAt: Date()
      )
    }
    return PerspectiveCommentPage(items: items, nextCursor: nil, hasNext: false)
  }

  func createComment(
    perspectiveId: Int,
    content: String
  ) async throws -> PerspectiveCommentMutationResult {
    let id = try battleID(for: perspectiveId)
    var value = try entry(for: id)
    let commentID = nextCommentID
    nextCommentID -= 1
    value.comments[commentID] = content
    entries[id] = value
    return PerspectiveCommentMutationResult(commentId: commentID, content: content, updatedAt: Date())
  }

  func updateComment(
    perspectiveId: Int,
    commentId: Int,
    content: String
  ) async throws -> PerspectiveCommentMutationResult {
    let id = try battleID(for: perspectiveId)
    var value = try entry(for: id)
    guard value.comments[commentId] != nil else { throw PerspectiveError.noData }
    value.comments[commentId] = content
    entries[id] = value
    return PerspectiveCommentMutationResult(commentId: commentId, content: content, updatedAt: Date())
  }

  func deleteComment(
    perspectiveId: Int,
    commentId: Int
  ) async throws {
    let id = try battleID(for: perspectiveId)
    var value = try entry(for: id)
    guard value.comments.removeValue(forKey: commentId) != nil else { throw PerspectiveError.noData }
    entries[id] = value
  }

  func updatePerspective(
    perspectiveId: Int,
    content: String
  ) async throws {
    let id = try battleID(for: perspectiveId)
    var value = try entry(for: id)
    guard value.perspectiveContent != nil else { throw PerspectiveError.noData }
    value.perspectiveContent = content
    entries[id] = value
  }

  func deletePerspective(perspectiveId: Int) async throws {
    let id = try battleID(for: perspectiveId)
    var value = try entry(for: id)
    value.perspectiveContent = nil
    value.comments = [:]
    entries[id] = value
  }

  func likePerspective(perspectiveId: Int) async throws -> CommentLikeResult {
    try setPerspectiveLike(perspectiveId: perspectiveId, liked: true)
  }

  func unlikePerspective(perspectiveId: Int) async throws -> CommentLikeResult {
    try setPerspectiveLike(perspectiveId: perspectiveId, liked: false)
  }

  func fetchPerspectiveLikes(perspectiveId: Int) async throws -> CommentLikeResult {
    let id = try battleID(for: perspectiveId)
    let liked = try entry(for: id).perspectiveLiked
    return CommentLikeResult(perspectiveId: perspectiveId, likeCount: liked ? 1 : 0, isLiked: liked)
  }

  private func setPerspectiveLike(
    perspectiveId: Int,
    liked: Bool
  ) throws -> CommentLikeResult {
    let id = try battleID(for: perspectiveId)
    var value = try entry(for: id)
    value.perspectiveLiked = liked
    entries[id] = value
    return CommentLikeResult(perspectiveId: perspectiveId, likeCount: liked ? 1 : 0, isLiked: liked)
  }

  func reportPerspective(perspectiveId: Int) async throws {
    _ = try battleID(for: perspectiveId)
  }

  func reportComment(
    perspectiveId: Int,
    commentId: Int
  ) async throws {
    let id = try battleID(for: perspectiveId)
    guard try entry(for: id).comments[commentId] != nil else { throw PerspectiveError.noData }
  }

  func likeComment(commentId: Int) async throws -> CommentLikeResult {
    CommentLikeResult(perspectiveId: commentId, likeCount: 1, isLiked: true)
  }

  func unlikeComment(commentId: Int) async throws -> CommentLikeResult {
    CommentLikeResult(perspectiveId: commentId, likeCount: 0, isLiked: false)
  }
}

private enum ClassMockChatSessionKey: DependencyKey {
  static let liveValue = ClassMockChatSession()
  static var testValue: ClassMockChatSession {
    ClassMockChatSession()
  }

  static var previewValue: ClassMockChatSession {
    ClassMockChatSession()
  }
}

extension DependencyValues {
  var classMockChatSession: ClassMockChatSession {
    get { self[ClassMockChatSessionKey.self] }
    set { self[ClassMockChatSessionKey.self] = newValue }
  }
}
