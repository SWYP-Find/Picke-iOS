//
//  CommentRequestMappingTests.swift
//  CommentDataTests
//

import Foundation
import Testing

@testable import CommentData

import NetworkHeader

struct CommentRequestMappingTests {
  @Test
  func like_urlPath_matchesCommentAPIDescription() {
    let service = CommentService.like(commentId: 123)

    #expect(service.urlPath == CommentAPI.like(commentId: 123).description)
    #expect(service.urlPath == "123/likes")
  }

  @Test
  func unlike_urlPath_matchesCommentAPIDescription() {
    let service = CommentService.unlike(commentId: 123)

    #expect(service.urlPath == CommentAPI.unlike(commentId: 123).description)
    #expect(service.urlPath == "123/likes")
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
  func headers_includeBaseHeaderFields() throws {
    let service = CommentService.like(commentId: 123)
    let request = try service.asURLRequest()

    #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
    #expect(request.value(forHTTPHeaderField: "Authorization")?.hasPrefix("Bearer ") == true)
  }
}
