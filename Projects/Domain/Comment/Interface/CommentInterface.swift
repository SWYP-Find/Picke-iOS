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

// UseCase 소비자용 별칭 — 인터페이스 강제(구현 모듈 import 불필요). pass-through 라 리포지토리 키로 해소.
public extension DependencyValues {
  var commentUseCase: CommentInterface {
    get { self[CommentRepositoryDependency.self] }
    set { self[CommentRepositoryDependency.self] = newValue }
  }
}
