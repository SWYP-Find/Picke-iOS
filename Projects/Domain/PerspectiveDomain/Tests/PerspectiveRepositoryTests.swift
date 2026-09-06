//
//  PerspectiveRepositoryTests.swift
//  PerspectiveDataTests
//

import Foundation
import Testing

@testable import PerspectiveData

import APIEndpoint
import CommentDomainInterface
import PerspectiveDomainInterface

struct PerspectiveRepositoryTests {
  // MARK: - fetchPerspective

  @Test
  func fetchPerspective_success_mapsToDomain() async throws {
    let json = """
    {
      "statusCode": 200,
      "data": {
        "perspectiveId": 42,
        "user": {
          "userTag": "user-1",
          "nickname": "닉네임",
          "characterType": "TYPE_A",
          "characterImageUrl": "https://example.com/a.png"
        },
        "option": {
          "optionId": 1,
          "label": "A",
          "title": "찬성",
          "stance": "AGREE"
        },
        "content": "관점 내용",
        "likeCount": 3,
        "commentCount": 2,
        "isLiked": true,
        "isMyPerspective": false,
        "createdAt": "2026-05-22T13:28:16.697Z"
      },
      "error": null
    }
    """
    let repo = PerspectiveRepositoryImpl(
      provider: StubNetworkProvider<PerspectiveService>(stubData: Data(json.utf8))
    )

    let result = try await repo.fetchPerspective(perspectiveId: 42)

    #expect(result.perspectiveId == 42)
    #expect(result.user.nickname == "닉네임")
    #expect(result.option.stance == "AGREE")
    #expect(result.content == "관점 내용")
    #expect(result.likeCount == 3)
    #expect(result.commentCount == 2)
    #expect(result.isLiked == true)
    #expect(result.isMyPerspective == false)
    #expect(result.createdAt != nil)
  }

  @Test
  func fetchPerspective_emptyData_throwsBackendErrorWithMessage() async throws {
    let json = """
    {
      "statusCode": 404,
      "data": null,
      "error": { "code": "PERSPECTIVE_404", "message": "존재하지 않는 관점입니다" }
    }
    """
    let repo = PerspectiveRepositoryImpl(
      provider: StubNetworkProvider<PerspectiveService>(stubData: Data(json.utf8))
    )

    await #expect(throws: PerspectiveError.backendError("존재하지 않는 관점입니다")) {
      try await repo.fetchPerspective(perspectiveId: 42)
    }
  }

  @Test
  func fetchPerspective_networkFailure_throws() async throws {
    let repo = PerspectiveRepositoryImpl(
      provider: ThrowingStubNetworkProvider<PerspectiveService>()
    )

    await #expect(throws: (any Error).self) {
      try await repo.fetchPerspective(perspectiveId: 42)
    }
  }

  // MARK: - fetchLabeledComments

  @Test
  func fetchLabeledComments_success_mapsToDomain() async throws {
    let json = """
    {
      "statusCode": 200,
      "data": {
        "items": [
          {
            "commentId": 7,
            "user": {
              "userTag": "u1",
              "nickname": "닉네임2",
              "characterType": "TYPE_B",
              "characterImageUrl": null
            },
            "stance": "DISAGREE",
            "content": "대댓글 내용",
            "likeCount": 1,
            "isLiked": false,
            "isMine": true,
            "createdAt": "2026-05-22T13:28:16.697Z"
          }
        ],
        "nextCursor": "cursor-2",
        "hasNext": true
      },
      "error": null
    }
    """
    let repo = PerspectiveRepositoryImpl(
      provider: StubNetworkProvider<PerspectiveService>(stubData: Data(json.utf8))
    )

    let result = try await repo.fetchLabeledComments(perspectiveId: 42, cursor: nil, size: 20)

    #expect(result.items.count == 1)
    #expect(result.items[0].commentId == 7)
    #expect(result.items[0].stance == "DISAGREE")
    #expect(result.items[0].isMine == true)
    #expect(result.nextCursor == "cursor-2")
    #expect(result.hasNext == true)
  }

  @Test
  func fetchLabeledComments_emptyItems_mapsToEmptyPage() async throws {
    let json = """
    {
      "statusCode": 200,
      "data": {
        "items": [],
        "nextCursor": null,
        "hasNext": false
      },
      "error": null
    }
    """
    let repo = PerspectiveRepositoryImpl(
      provider: StubNetworkProvider<PerspectiveService>(stubData: Data(json.utf8))
    )

    let result = try await repo.fetchLabeledComments(perspectiveId: 42, cursor: nil, size: nil)

    #expect(result.items.isEmpty)
    #expect(result.nextCursor == nil)
    #expect(result.hasNext == false)
  }

  @Test
  func fetchLabeledComments_emptyData_throwsBackendErrorWithDefaultMessage() async throws {
    let json = """
    {
      "statusCode": 500,
      "data": null,
      "error": null
    }
    """
    let repo = PerspectiveRepositoryImpl(
      provider: StubNetworkProvider<PerspectiveService>(stubData: Data(json.utf8))
    )

    await #expect(throws: CommentError.backendError("대댓글 목록 응답이 비어 있습니다")) {
      try await repo.fetchLabeledComments(perspectiveId: 42, cursor: nil, size: nil)
    }
  }

  @Test
  func fetchLabeledComments_networkFailure_throws() async throws {
    let repo = PerspectiveRepositoryImpl(
      provider: ThrowingStubNetworkProvider<PerspectiveService>()
    )

    await #expect(throws: (any Error).self) {
      try await repo.fetchLabeledComments(perspectiveId: 42, cursor: nil, size: nil)
    }
  }

  // MARK: - createComment

  @Test
  func createComment_success_mapsToDomain() async throws {
    let json = """
    {
      "statusCode": 200,
      "data": {
        "commentId": 9,
        "content": "새 댓글",
        "updatedAt": null
      },
      "error": null
    }
    """
    let repo = PerspectiveRepositoryImpl(
      provider: StubNetworkProvider<PerspectiveService>(stubData: Data(json.utf8))
    )

    let result = try await repo.createComment(perspectiveId: 42, content: "새 댓글")

    #expect(result == PerspectiveCommentMutationResult(commentId: 9, content: "새 댓글", updatedAt: nil))
  }

  @Test
  func createComment_emptyData_throwsBackendErrorWithMessage() async throws {
    let json = """
    {
      "statusCode": 400,
      "data": null,
      "error": { "code": "COMMENT_400", "message": "댓글 작성에 실패했습니다" }
    }
    """
    let repo = PerspectiveRepositoryImpl(
      provider: StubNetworkProvider<PerspectiveService>(stubData: Data(json.utf8))
    )

    await #expect(throws: CommentError.backendError("댓글 작성에 실패했습니다")) {
      try await repo.createComment(perspectiveId: 42, content: "새 댓글")
    }
  }

  @Test
  func createComment_networkFailure_throws() async throws {
    let repo = PerspectiveRepositoryImpl(
      provider: ThrowingStubNetworkProvider<PerspectiveService>()
    )

    await #expect(throws: (any Error).self) {
      try await repo.createComment(perspectiveId: 42, content: "새 댓글")
    }
  }

  // MARK: - updateComment

  @Test
  func updateComment_success_mapsToDomain() async throws {
    let json = """
    {
      "statusCode": 200,
      "data": {
        "commentId": 9,
        "content": "수정된 댓글",
        "updatedAt": "2026-05-22T13:28:16.697Z"
      },
      "error": null
    }
    """
    let repo = PerspectiveRepositoryImpl(
      provider: StubNetworkProvider<PerspectiveService>(stubData: Data(json.utf8))
    )

    let result = try await repo.updateComment(perspectiveId: 42, commentId: 9, content: "수정된 댓글")

    #expect(result.commentId == 9)
    #expect(result.content == "수정된 댓글")
    #expect(result.updatedAt != nil)
  }

  @Test
  func updateComment_emptyData_throwsBackendErrorWithMessage() async throws {
    let json = """
    {
      "statusCode": 400,
      "data": null,
      "error": { "code": "COMMENT_400", "message": "댓글 수정에 실패했습니다" }
    }
    """
    let repo = PerspectiveRepositoryImpl(
      provider: StubNetworkProvider<PerspectiveService>(stubData: Data(json.utf8))
    )

    await #expect(throws: CommentError.backendError("댓글 수정에 실패했습니다")) {
      try await repo.updateComment(perspectiveId: 42, commentId: 9, content: "수정된 댓글")
    }
  }

  @Test
  func updateComment_networkFailure_throws() async throws {
    let repo = PerspectiveRepositoryImpl(
      provider: ThrowingStubNetworkProvider<PerspectiveService>()
    )

    await #expect(throws: (any Error).self) {
      try await repo.updateComment(perspectiveId: 42, commentId: 9, content: "수정된 댓글")
    }
  }

  // MARK: - deleteComment

  @Test
  func deleteComment_success_doesNotThrow() async throws {
    let json = """
    {
      "statusCode": 200,
      "data": {},
      "error": null
    }
    """
    let repo = PerspectiveRepositoryImpl(
      provider: StubNetworkProvider<PerspectiveService>(stubData: Data(json.utf8))
    )

    try await repo.deleteComment(perspectiveId: 42, commentId: 9)
  }

  @Test
  func deleteComment_statusCode400_throwsBackendErrorWithMessage() async throws {
    let json = """
    {
      "statusCode": 400,
      "data": null,
      "error": { "code": "COMMENT_400", "message": "댓글 삭제에 실패했습니다" }
    }
    """
    let repo = PerspectiveRepositoryImpl(
      provider: StubNetworkProvider<PerspectiveService>(stubData: Data(json.utf8))
    )

    await #expect(throws: CommentError.backendError("댓글 삭제에 실패했습니다")) {
      try await repo.deleteComment(perspectiveId: 42, commentId: 9)
    }
  }

  @Test
  func deleteComment_networkFailure_throws() async throws {
    let repo = PerspectiveRepositoryImpl(
      provider: ThrowingStubNetworkProvider<PerspectiveService>()
    )

    await #expect(throws: (any Error).self) {
      try await repo.deleteComment(perspectiveId: 42, commentId: 9)
    }
  }

  // MARK: - updatePerspective

  @Test
  func updatePerspective_success_doesNotThrow() async throws {
    let json = """
    {
      "statusCode": 200,
      "data": {},
      "error": null
    }
    """
    let repo = PerspectiveRepositoryImpl(
      provider: StubNetworkProvider<PerspectiveService>(stubData: Data(json.utf8))
    )

    try await repo.updatePerspective(perspectiveId: 42, content: "관점 수정 내용")
  }

  @Test
  func updatePerspective_statusCode400_throwsBackendErrorWithMessage() async throws {
    let json = """
    {
      "statusCode": 400,
      "data": null,
      "error": { "code": "PERSPECTIVE_400", "message": "관점 수정에 실패했습니다" }
    }
    """
    let repo = PerspectiveRepositoryImpl(
      provider: StubNetworkProvider<PerspectiveService>(stubData: Data(json.utf8))
    )

    await #expect(throws: PerspectiveError.backendError("관점 수정에 실패했습니다")) {
      try await repo.updatePerspective(perspectiveId: 42, content: "관점 수정 내용")
    }
  }

  @Test
  func updatePerspective_networkFailure_throws() async throws {
    let repo = PerspectiveRepositoryImpl(
      provider: ThrowingStubNetworkProvider<PerspectiveService>()
    )

    await #expect(throws: (any Error).self) {
      try await repo.updatePerspective(perspectiveId: 42, content: "관점 수정 내용")
    }
  }

  // MARK: - deletePerspective

  @Test
  func deletePerspective_success_doesNotThrow() async throws {
    let json = """
    {
      "statusCode": 200,
      "data": "OK",
      "error": null
    }
    """
    let repo = PerspectiveRepositoryImpl(
      provider: StubNetworkProvider<PerspectiveService>(stubData: Data(json.utf8))
    )

    try await repo.deletePerspective(perspectiveId: 42)
  }

  @Test
  func deletePerspective_statusCode400_throwsBackendErrorWithMessage() async throws {
    let json = """
    {
      "statusCode": 400,
      "data": null,
      "error": { "code": "PERSPECTIVE_400", "message": "관점 삭제에 실패했습니다" }
    }
    """
    let repo = PerspectiveRepositoryImpl(
      provider: StubNetworkProvider<PerspectiveService>(stubData: Data(json.utf8))
    )

    await #expect(throws: PerspectiveError.backendError("관점 삭제에 실패했습니다")) {
      try await repo.deletePerspective(perspectiveId: 42)
    }
  }

  @Test
  func deletePerspective_networkFailure_throws() async throws {
    let repo = PerspectiveRepositoryImpl(
      provider: ThrowingStubNetworkProvider<PerspectiveService>()
    )

    await #expect(throws: (any Error).self) {
      try await repo.deletePerspective(perspectiveId: 42)
    }
  }

  // MARK: - likePerspective

  @Test
  func likePerspective_success_isLikedAlwaysTrue() async throws {
    let json = """
    {
      "statusCode": 200,
      "data": {
        "perspectiveId": 42,
        "likeCount": 5,
        "isLiked": null
      },
      "error": null
    }
    """
    let repo = PerspectiveRepositoryImpl(
      provider: StubNetworkProvider<PerspectiveService>(stubData: Data(json.utf8))
    )

    let result = try await repo.likePerspective(perspectiveId: 42)

    #expect(result == CommentLikeResult(perspectiveId: 42, likeCount: 5, isLiked: true))
  }

  @Test
  func likePerspective_emptyData_throwsBackendErrorWithMessage() async throws {
    let json = """
    {
      "statusCode": 400,
      "data": null,
      "error": { "code": "PERSPECTIVE_400", "message": "이미 좋아요한 관점입니다" }
    }
    """
    let repo = PerspectiveRepositoryImpl(
      provider: StubNetworkProvider<PerspectiveService>(stubData: Data(json.utf8))
    )

    await #expect(throws: CommentError.backendError("이미 좋아요한 관점입니다")) {
      try await repo.likePerspective(perspectiveId: 42)
    }
  }

  @Test
  func likePerspective_networkFailure_throws() async throws {
    let repo = PerspectiveRepositoryImpl(
      provider: ThrowingStubNetworkProvider<PerspectiveService>()
    )

    await #expect(throws: (any Error).self) {
      try await repo.likePerspective(perspectiveId: 42)
    }
  }

  // MARK: - unlikePerspective

  @Test
  func unlikePerspective_success_isLikedAlwaysFalse() async throws {
    let json = """
    {
      "statusCode": 200,
      "data": {
        "perspectiveId": 42,
        "likeCount": 4,
        "isLiked": null
      },
      "error": null
    }
    """
    let repo = PerspectiveRepositoryImpl(
      provider: StubNetworkProvider<PerspectiveService>(stubData: Data(json.utf8))
    )

    let result = try await repo.unlikePerspective(perspectiveId: 42)

    #expect(result == CommentLikeResult(perspectiveId: 42, likeCount: 4, isLiked: false))
  }

  @Test
  func unlikePerspective_emptyData_throwsBackendErrorWithDefaultMessage() async throws {
    let json = """
    {
      "statusCode": 500,
      "data": null,
      "error": null
    }
    """
    let repo = PerspectiveRepositoryImpl(
      provider: StubNetworkProvider<PerspectiveService>(stubData: Data(json.utf8))
    )

    await #expect(throws: CommentError.backendError("관점 좋아요 취소 응답이 비어 있습니다")) {
      try await repo.unlikePerspective(perspectiveId: 42)
    }
  }

  @Test
  func unlikePerspective_networkFailure_throws() async throws {
    let repo = PerspectiveRepositoryImpl(
      provider: ThrowingStubNetworkProvider<PerspectiveService>()
    )

    await #expect(throws: (any Error).self) {
      try await repo.unlikePerspective(perspectiveId: 42)
    }
  }

  // MARK: - fetchPerspectiveLikes

  @Test
  func fetchPerspectiveLikes_success_mapsToDomain() async throws {
    let json = """
    {
      "statusCode": 200,
      "data": {
        "perspectiveId": 42,
        "likeCount": 6,
        "isLiked": true
      },
      "error": null
    }
    """
    let repo = PerspectiveRepositoryImpl(
      provider: StubNetworkProvider<PerspectiveService>(stubData: Data(json.utf8))
    )

    let result = try await repo.fetchPerspectiveLikes(perspectiveId: 42)

    #expect(result == CommentLikeResult(perspectiveId: 42, likeCount: 6, isLiked: true))
  }

  @Test
  func fetchPerspectiveLikes_missingIsLiked_defaultsToFalse() async throws {
    let json = """
    {
      "statusCode": 200,
      "data": {
        "perspectiveId": 42,
        "likeCount": 6,
        "isLiked": null
      },
      "error": null
    }
    """
    let repo = PerspectiveRepositoryImpl(
      provider: StubNetworkProvider<PerspectiveService>(stubData: Data(json.utf8))
    )

    let result = try await repo.fetchPerspectiveLikes(perspectiveId: 42)

    #expect(result.isLiked == false)
  }

  @Test
  func fetchPerspectiveLikes_emptyData_throwsBackendErrorWithMessage() async throws {
    let json = """
    {
      "statusCode": 404,
      "data": null,
      "error": { "code": "PERSPECTIVE_404", "message": "좋아요 정보를 찾을 수 없습니다" }
    }
    """
    let repo = PerspectiveRepositoryImpl(
      provider: StubNetworkProvider<PerspectiveService>(stubData: Data(json.utf8))
    )

    await #expect(throws: CommentError.backendError("좋아요 정보를 찾을 수 없습니다")) {
      try await repo.fetchPerspectiveLikes(perspectiveId: 42)
    }
  }

  @Test
  func fetchPerspectiveLikes_networkFailure_throws() async throws {
    let repo = PerspectiveRepositoryImpl(
      provider: ThrowingStubNetworkProvider<PerspectiveService>()
    )

    await #expect(throws: (any Error).self) {
      try await repo.fetchPerspectiveLikes(perspectiveId: 42)
    }
  }

  // MARK: - reportPerspective

  @Test
  func reportPerspective_success_doesNotThrow() async throws {
    let json = """
    {
      "statusCode": 200,
      "data": "OK",
      "error": null
    }
    """
    let repo = PerspectiveRepositoryImpl(
      provider: StubNetworkProvider<PerspectiveService>(stubData: Data(json.utf8))
    )

    try await repo.reportPerspective(perspectiveId: 42)
  }

  @Test
  func reportPerspective_statusCode400_throwsBackendErrorWithDefaultMessage() async throws {
    let json = """
    {
      "statusCode": 400,
      "data": null,
      "error": null
    }
    """
    let repo = PerspectiveRepositoryImpl(
      provider: StubNetworkProvider<PerspectiveService>(stubData: Data(json.utf8))
    )

    await #expect(throws: CommentError.backendError("관점 신고 실패")) {
      try await repo.reportPerspective(perspectiveId: 42)
    }
  }

  @Test
  func reportPerspective_networkFailure_throws() async throws {
    let repo = PerspectiveRepositoryImpl(
      provider: ThrowingStubNetworkProvider<PerspectiveService>()
    )

    await #expect(throws: (any Error).self) {
      try await repo.reportPerspective(perspectiveId: 42)
    }
  }

  // MARK: - reportComment

  @Test
  func reportComment_success_doesNotThrow() async throws {
    let json = """
    {
      "statusCode": 200,
      "data": "OK",
      "error": null
    }
    """
    let repo = PerspectiveRepositoryImpl(
      provider: StubNetworkProvider<PerspectiveService>(stubData: Data(json.utf8))
    )

    try await repo.reportComment(perspectiveId: 42, commentId: 9)
  }

  @Test
  func reportComment_statusCode400_throwsBackendErrorWithDefaultMessage() async throws {
    let json = """
    {
      "statusCode": 400,
      "data": null,
      "error": null
    }
    """
    let repo = PerspectiveRepositoryImpl(
      provider: StubNetworkProvider<PerspectiveService>(stubData: Data(json.utf8))
    )

    await #expect(throws: CommentError.backendError("댓글 신고 실패")) {
      try await repo.reportComment(perspectiveId: 42, commentId: 9)
    }
  }

  @Test
  func reportComment_networkFailure_throws() async throws {
    let repo = PerspectiveRepositoryImpl(
      provider: ThrowingStubNetworkProvider<PerspectiveService>()
    )

    await #expect(throws: (any Error).self) {
      try await repo.reportComment(perspectiveId: 42, commentId: 9)
    }
  }
}
