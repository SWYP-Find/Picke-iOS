//
//  CommentUseCase.swift
//  UseCase
//

import Foundation

import DomainInterface
import Entity

import ComposableArchitecture

public struct CommentUseCaseImpl: CommentInterface {
  @Dependency(\.commentRepository) private var commentRepository

  public init() {}

  public func likeComment(commentId: Int) async throws -> CommentLikeResult {
    return try await commentRepository.likeComment(commentId: commentId)
  }

  public func unlikeComment(commentId: Int) async throws -> CommentLikeResult {
    return try await commentRepository.unlikeComment(commentId: commentId)
  }
}

extension CommentUseCaseImpl: DependencyKey {
  public static var liveValue = CommentUseCaseImpl()
  public static var testValue = CommentUseCaseImpl()
  public static var previewValue = CommentUseCaseImpl()
}

public extension DependencyValues {
  var commentUseCase: CommentUseCaseImpl {
    get { self[CommentUseCaseImpl.self] }
    set { self[CommentUseCaseImpl.self] = newValue }
  }
}
