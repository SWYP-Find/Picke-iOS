//
//  PerspectiveRequestMappingTests.swift
//  PerspectiveDataTests
//

import Foundation
import Testing

@testable import PerspectiveDomain

import APIEndpoint
@testable import PickeNetwork

struct PerspectiveRequestMappingTests {
  // MARK: - detail

  @Test func detail_요청은_GET_이며_경로가_perspectives_id_이다() throws {
    let request = try PerspectiveService.detail(perspectiveId: 42).asURLRequest()

    #expect(request.url?.path == "/api/v1/perspectives/42")
    #expect(request.httpMethod == "GET")
  }

  @Test func detail_요청은_파라미터가_없다() throws {
    let request = try PerspectiveService.detail(perspectiveId: 42).asURLRequest()

    #expect(request.url?.query == nil)
    #expect(request.httpBody == nil)
  }

  // MARK: - listLabeledComments

  @Test func listLabeledComments_요청은_GET_이며_경로가_comments_labeled_이다() throws {
    let request = try PerspectiveService.listLabeledComments(
      perspectiveId: 42,
      cursor: "cursor-1",
      size: 20
    ).asURLRequest()

    #expect(request.url?.path == "/api/v1/perspectives/42/comments/labeled")
    #expect(request.httpMethod == "GET")
  }

  @Test func listLabeledComments_요청은_cursor_size_쿼리를_포함한다() throws {
    let request = try PerspectiveService.listLabeledComments(
      perspectiveId: 42,
      cursor: "cursor-1",
      size: 20
    ).asURLRequest()

    let query = try #require(request.url?.query)
    #expect(query.contains("cursor=cursor-1"))
    #expect(query.contains("size=20"))
  }

  @Test func listLabeledComments_요청은_cursor_size_가_nil_이면_쿼리가_없다() throws {
    let request = try PerspectiveService.listLabeledComments(
      perspectiveId: 42,
      cursor: nil,
      size: nil
    ).asURLRequest()

    #expect(request.url?.query == nil)
  }

  // MARK: - createComment

  @Test func createComment_요청은_POST_이며_경로가_comments_이다() throws {
    let request = try PerspectiveService.createComment(
      perspectiveId: 42,
      body: PerspectiveCommentBody(content: "댓글 내용")
    ).asURLRequest()

    #expect(request.url?.path == "/api/v1/perspectives/42/comments")
    #expect(request.httpMethod == "POST")
  }

  @Test func createComment_요청은_content_를_JSON_바디에_포함한다() throws {
    let request = try PerspectiveService.createComment(
      perspectiveId: 42,
      body: PerspectiveCommentBody(content: "댓글 내용")
    ).asURLRequest()

    let body = try #require(request.httpBody)
    let json = try JSONSerialization.jsonObject(with: body) as? [String: Any]
    #expect(json?["content"] as? String == "댓글 내용")
  }

  // MARK: - updateComment

  @Test func updateComment_요청은_PATCH_이며_경로가_comments_commentId_이다() throws {
    let request = try PerspectiveService.updateComment(
      perspectiveId: 42,
      commentId: 7,
      body: PerspectiveCommentBody(content: "수정된 내용")
    ).asURLRequest()

    #expect(request.url?.path == "/api/v1/perspectives/42/comments/7")
    #expect(request.httpMethod == "PATCH")
  }

  @Test func updateComment_요청은_content_를_JSON_바디에_포함한다() throws {
    let request = try PerspectiveService.updateComment(
      perspectiveId: 42,
      commentId: 7,
      body: PerspectiveCommentBody(content: "수정된 내용")
    ).asURLRequest()

    let body = try #require(request.httpBody)
    let json = try JSONSerialization.jsonObject(with: body) as? [String: Any]
    #expect(json?["content"] as? String == "수정된 내용")
  }

  // MARK: - deleteComment

  @Test func deleteComment_요청은_DELETE_이며_경로가_comments_commentId_이다() throws {
    let request = try PerspectiveService.deleteComment(
      perspectiveId: 42,
      commentId: 7
    ).asURLRequest()

    #expect(request.url?.path == "/api/v1/perspectives/42/comments/7")
    #expect(request.httpMethod == "DELETE")
  }

  @Test func deleteComment_요청은_파라미터가_없다() throws {
    let request = try PerspectiveService.deleteComment(
      perspectiveId: 42,
      commentId: 7
    ).asURLRequest()

    #expect(request.url?.query == nil)
    #expect(request.httpBody == nil)
  }

  // MARK: - updatePerspective

  @Test func updatePerspective_요청은_PATCH_이며_경로가_perspectives_id_이다() throws {
    let request = try PerspectiveService.updatePerspective(
      perspectiveId: 42,
      body: PerspectiveCommentBody(content: "관점 수정 내용")
    ).asURLRequest()

    #expect(request.url?.path == "/api/v1/perspectives/42")
    #expect(request.httpMethod == "PATCH")
  }

  @Test func updatePerspective_요청은_content_를_JSON_바디에_포함한다() throws {
    let request = try PerspectiveService.updatePerspective(
      perspectiveId: 42,
      body: PerspectiveCommentBody(content: "관점 수정 내용")
    ).asURLRequest()

    let body = try #require(request.httpBody)
    let json = try JSONSerialization.jsonObject(with: body) as? [String: Any]
    #expect(json?["content"] as? String == "관점 수정 내용")
  }

  // MARK: - deletePerspective

  @Test func deletePerspective_요청은_DELETE_이며_경로가_perspectives_id_이다() throws {
    let request = try PerspectiveService.deletePerspective(perspectiveId: 42).asURLRequest()

    #expect(request.url?.path == "/api/v1/perspectives/42")
    #expect(request.httpMethod == "DELETE")
  }

  @Test func deletePerspective_요청은_파라미터가_없다() throws {
    let request = try PerspectiveService.deletePerspective(perspectiveId: 42).asURLRequest()

    #expect(request.url?.query == nil)
    #expect(request.httpBody == nil)
  }

  // MARK: - likePerspective

  @Test func likePerspective_요청은_POST_이며_경로가_likes_이다() throws {
    let request = try PerspectiveService.likePerspective(perspectiveId: 42).asURLRequest()

    #expect(request.url?.path == "/api/v1/perspectives/42/likes")
    #expect(request.httpMethod == "POST")
  }

  @Test func likePerspective_요청은_파라미터가_없다() throws {
    let request = try PerspectiveService.likePerspective(perspectiveId: 42).asURLRequest()

    #expect(request.url?.query == nil)
    #expect(request.httpBody == nil)
  }

  // MARK: - unlikePerspective

  @Test func unlikePerspective_요청은_DELETE_이며_경로가_likes_이다() throws {
    let request = try PerspectiveService.unlikePerspective(perspectiveId: 42).asURLRequest()

    #expect(request.url?.path == "/api/v1/perspectives/42/likes")
    #expect(request.httpMethod == "DELETE")
  }

  // MARK: - fetchPerspectiveLikes

  @Test func fetchPerspectiveLikes_요청은_GET_이며_경로가_likes_이다() throws {
    let request = try PerspectiveService.fetchPerspectiveLikes(perspectiveId: 42).asURLRequest()

    #expect(request.url?.path == "/api/v1/perspectives/42/likes")
    #expect(request.httpMethod == "GET")
  }

  // MARK: - reportPerspective

  @Test func reportPerspective_요청은_POST_이며_경로가_reports_이다() throws {
    let request = try PerspectiveService.reportPerspective(perspectiveId: 42).asURLRequest()

    #expect(request.url?.path == "/api/v1/perspectives/42/reports")
    #expect(request.httpMethod == "POST")
  }

  @Test func reportPerspective_요청은_파라미터가_없다() throws {
    let request = try PerspectiveService.reportPerspective(perspectiveId: 42).asURLRequest()

    #expect(request.url?.query == nil)
    #expect(request.httpBody == nil)
  }

  // MARK: - reportComment

  @Test func reportComment_요청은_POST_이며_경로가_comments_commentId_reports_이다() throws {
    let request = try PerspectiveService.reportComment(
      perspectiveId: 42,
      commentId: 7
    ).asURLRequest()

    #expect(request.url?.path == "/api/v1/perspectives/42/comments/7/reports")
    #expect(request.httpMethod == "POST")
  }

  @Test func reportComment_요청은_파라미터가_없다() throws {
    let request = try PerspectiveService.reportComment(
      perspectiveId: 42,
      commentId: 7
    ).asURLRequest()

    #expect(request.url?.query == nil)
    #expect(request.httpBody == nil)
  }

  // MARK: - headers

  @Test func 모든_요청은_자동_인증_정책을_사용한다() {
    let services: [PerspectiveService] = [
      .detail(perspectiveId: 42),
      .listLabeledComments(perspectiveId: 42, cursor: nil, size: nil),
      .createComment(perspectiveId: 42, body: PerspectiveCommentBody(content: "댓글")),
      .updateComment(perspectiveId: 42, commentId: 7, body: PerspectiveCommentBody(content: "댓글")),
      .deleteComment(perspectiveId: 42, commentId: 7),
      .updatePerspective(perspectiveId: 42, body: PerspectiveCommentBody(content: "관점")),
      .deletePerspective(perspectiveId: 42),
      .likePerspective(perspectiveId: 42),
      .unlikePerspective(perspectiveId: 42),
      .fetchPerspectiveLikes(perspectiveId: 42),
      .reportPerspective(perspectiveId: 42),
      .reportComment(perspectiveId: 42, commentId: 7),
    ]

    for service in services {
      #expect(service.authorization == .automatic)
    }
  }
}
