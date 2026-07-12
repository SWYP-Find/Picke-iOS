//
//  CommentService.swift
//  Service
//

import Foundation

import API
import NetworkHeader

import AsyncMoya

public enum CommentService {
  case like(commentId: Int)
  case unlike(commentId: Int)
}

extension CommentService: BaseTargetType {
  public typealias Domain = PieckeDomain

  public var domain: PieckeDomain { .comment }

  public var urlPath: String {
    switch self {
    case let .like(commentId):
      CommentAPI.like(commentId: commentId).description
    case let .unlike(commentId):
      CommentAPI.unlike(commentId: commentId).description
    }
  }

  public var error: [Int: AsyncMoya.NetworkError]? { nil }

  public var method: Moya.Method {
    switch self {
    case .like:
      .post
    case .unlike:
      .delete
    }
  }

  public var parameters: [String: Any]? { nil }

  public var headers: [String: String]? {
    APIHeader.baseHeader
  }
}
