//
//  CommentUseCase.swift
//  CommentDomain
//
//  Created by Picke on 10/11/26.
//

import Foundation

import CommentDomainInterface

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

