//
//  CommentInterface.swift
//  DomainInterface
//

import CommonDomainInterface
import Dependencies
import Foundation
import WeaveDI

public protocol CommentInterface: Sendable {
  func likeComment(commentId: Int) async throws -> CommentLikeResult
  func unlikeComment(commentId: Int) async throws -> CommentLikeResult
}

public struct DefaultCommentRepositoryImpl: CommentInterface {
  public init() {}

  public func likeComment(commentId: Int) async throws -> CommentLikeResult {
    CommentLikeResult(perspectiveId: commentId, likeCount: 0, isLiked: true)
  }

  public func unlikeComment(commentId: Int) async throws -> CommentLikeResult {
    CommentLikeResult(perspectiveId: commentId, likeCount: 0, isLiked: false)
  }
}

public struct CommentRepositoryDependency: DependencyKey {
  public static var liveValue: CommentInterface {
    UnifiedDI.resolve(CommentInterface.self) ?? DefaultCommentRepositoryImpl()
  }

  public static var testValue: CommentInterface {
    UnifiedDI.resolve(CommentInterface.self) ?? DefaultCommentRepositoryImpl()
  }

  public static var previewValue: CommentInterface = liveValue
}

public extension DependencyValues {
  var commentRepository: CommentInterface {
    get { self[CommentRepositoryDependency.self] }
    set { self[CommentRepositoryDependency.self] = newValue }
  }
}
