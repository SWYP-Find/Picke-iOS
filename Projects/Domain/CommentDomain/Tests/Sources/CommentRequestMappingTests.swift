//
//  CommentRequestMappingTests.swift
//  CommentDataTests
//

import Foundation
import Testing

@testable import CommentDomain

import API
import APIEndpoint
@testable import PickeNetwork

struct CommentRequestMappingTests {
  @Test
  func like_path_matchesCommentAPIDescription() {
    let service = CommentService.like(commentId: 123)

    #expect(service.path == CommentAPI.like(commentId: 123).description)
    #expect(service.path == "123/likes")
  }

  @Test
  func unlike_path_matchesCommentAPIDescription() {
    let service = CommentService.unlike(commentId: 123)

    #expect(service.path == CommentAPI.unlike(commentId: 123).description)
    #expect(service.path == "123/likes")
  }

  @Test
  func like_request_isPOSTWithNoBody() throws {
    let service = CommentService.like(commentId: 123)
    let request = try service.asURLRequest()

    #expect(service.method == .post)
    #expect(request.url?.path == "/api/v1/comments/123/likes")
    #expect(request.httpBody == nil)
  }

  @Test
  func unlike_request_isDELETEWithNoBody() throws {
    let service = CommentService.unlike(commentId: 456)
    let request = try service.asURLRequest()

    #expect(service.method == .delete)
    #expect(request.url?.path == "/api/v1/comments/456/likes")
    #expect(request.httpBody == nil)
  }

  @Test
  func parameters_areAlwaysNil() {
    #expect(CommentService.like(commentId: 1).parameters == nil)
    #expect(CommentService.unlike(commentId: 1).parameters == nil)
  }

  @Test
  func allCases_useAutomaticAuthorizationPolicy() {
    #expect(CommentService.like(commentId: 123).authorization == .automatic)
    #expect(CommentService.unlike(commentId: 123).authorization == .automatic)
  }
}
