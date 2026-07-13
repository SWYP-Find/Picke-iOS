//
//  PerspectiveInterface.swift
//  PerspectiveDomainInterface
//

import CommentDomainInterface
import CommonDomainInterface
import Dependencies
import Foundation
import WeaveDI

public protocol PerspectiveInterface: Sendable {
  func fetchPerspective(perspectiveId: Int) async throws -> BattlePerspective
  func fetchLabeledComments(
    perspectiveId: Int,
    cursor: String?,
    size: Int?
  ) async throws -> PerspectiveCommentPage
  func createComment(
    perspectiveId: Int,
    content: String
  ) async throws -> PerspectiveCommentMutationResult
  func updateComment(
    perspectiveId: Int,
    commentId: Int,
    content: String
  ) async throws -> PerspectiveCommentMutationResult
  func deleteComment(
    perspectiveId: Int,
    commentId: Int
  ) async throws
  func updatePerspective(perspectiveId: Int, content: String) async throws
  func deletePerspective(perspectiveId: Int) async throws
  func likePerspective(perspectiveId: Int) async throws -> CommentLikeResult
  func unlikePerspective(perspectiveId: Int) async throws -> CommentLikeResult
  func fetchPerspectiveLikes(perspectiveId: Int) async throws -> CommentLikeResult
  func reportPerspective(perspectiveId: Int) async throws
  func reportComment(perspectiveId: Int, commentId: Int) async throws
}

public struct PerspectiveRepositoryDependency: DependencyKey {
  public static var liveValue: PerspectiveInterface {
    UnifiedDI.resolve(PerspectiveInterface.self) ?? DefaultPerspectiveRepositoryImpl()
  }

  public static var testValue: PerspectiveInterface {
    UnifiedDI.resolve(PerspectiveInterface.self) ?? DefaultPerspectiveRepositoryImpl()
  }

  public static var previewValue: PerspectiveInterface = liveValue
}

public extension DependencyValues {
  var perspectiveRepository: PerspectiveInterface {
    get { self[PerspectiveRepositoryDependency.self] }
    set { self[PerspectiveRepositoryDependency.self] = newValue }
  }
}

// UseCase 소비자용 별칭 — 인터페이스 강제(구현 모듈 import 불필요). pass-through 라 리포지토리 키로 해소.
public extension DependencyValues {
  var perspectiveUseCase: PerspectiveInterface {
    get { self[PerspectiveRepositoryDependency.self] }
    set { self[PerspectiveRepositoryDependency.self] = newValue }
  }
}
