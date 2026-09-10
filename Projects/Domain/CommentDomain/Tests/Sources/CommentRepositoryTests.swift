//
//  CommentRepositoryTests.swift
//  CommentDataTests
//

import Foundation

import Dependencies
import Testing

@testable import CommentDomain

import APIEndpoint
import CommentDomainInterface

struct CommentRepositoryTests {
  // MARK: - likeComment

  @Test
  func likeComment_success_mapsToDomain() async throws {
    let json = """
    {
      "statusCode": 200,
      "data": {
        "perspectiveId": 10,
        "likeCount": 5,
        "isLiked": true
      },
      "error": null
    }
    """
    let repo = withDependencies {
      $0.networkClient = StubNetworkClient(stubData: Data(json.utf8))
    } operation: {
      CommentRepositoryImpl()
    }

    let result = try await repo.likeComment(commentId: 10)

    #expect(result == CommentLikeResult(perspectiveId: 10, likeCount: 5, isLiked: true))
  }

  @Test
  func likeComment_missingIsLiked_defaultsToFalse() async throws {
    let json = """
    {
      "statusCode": 200,
      "data": {
        "perspectiveId": 10,
        "likeCount": 5,
        "isLiked": null
      },
      "error": null
    }
    """
    let repo = withDependencies {
      $0.networkClient = StubNetworkClient(stubData: Data(json.utf8))
    } operation: {
      CommentRepositoryImpl()
    }

    let result = try await repo.likeComment(commentId: 10)

    #expect(result.isLiked == false)
  }

  @Test
  func likeComment_errorEnvelope_throwsNetworkResponseError() async throws {
    let json = """
    {
      "statusCode": 400,
      "data": null,
      "error": { "code": "COMMENT_400", "message": "이미 좋아요한 댓글입니다" }
    }
    """
    let repo = withDependencies {
      $0.networkClient = StubNetworkClient(stubData: Data(json.utf8))
    } operation: {
      CommentRepositoryImpl()
    }

    await expectNetworkResponseError(
      statusCode: 400,
      code: "COMMENT_400",
      message: "이미 좋아요한 댓글입니다"
    ) {
      try await repo.likeComment(commentId: 10)
    }
  }

  @Test
  func likeComment_networkFailure_throws() async throws {
    let repo = withDependencies {
      $0.networkClient = ThrowingStubNetworkClient()
    } operation: {
      CommentRepositoryImpl()
    }

    await #expect(throws: (any Error).self) {
      try await repo.likeComment(commentId: 10)
    }
  }

  // MARK: - unlikeComment

  @Test
  func unlikeComment_success_mapsToDomain() async throws {
    let json = """
    {
      "statusCode": 200,
      "data": {
        "perspectiveId": 10,
        "likeCount": 4,
        "isLiked": false
      },
      "error": null
    }
    """
    let repo = withDependencies {
      $0.networkClient = StubNetworkClient(stubData: Data(json.utf8))
    } operation: {
      CommentRepositoryImpl()
    }

    let result = try await repo.unlikeComment(commentId: 10)

    #expect(result == CommentLikeResult(perspectiveId: 10, likeCount: 4, isLiked: false))
  }

  @Test
  func unlikeComment_emptyData_throwsNetworkDataMissing() async throws {
    let json = """
    {
      "statusCode": 500,
      "data": null,
      "error": null
    }
    """
    let repo = withDependencies {
      $0.networkClient = StubNetworkClient(stubData: Data(json.utf8))
    } operation: {
      CommentRepositoryImpl()
    }

    await expectNetworkDataMissing {
      try await repo.unlikeComment(commentId: 10)
    }
  }

  @Test
  func unlikeComment_networkFailure_throws() async throws {
    let repo = withDependencies {
      $0.networkClient = ThrowingStubNetworkClient()
    } operation: {
      CommentRepositoryImpl()
    }

    await #expect(throws: (any Error).self) {
      try await repo.unlikeComment(commentId: 10)
    }
  }
}
