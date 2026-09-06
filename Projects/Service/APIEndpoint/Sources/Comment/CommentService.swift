//
//  CommentService.swift
//  Service
//

import Foundation

import API
import PickeNetwork


public enum CommentService {
  case like(commentId: Int)
  case unlike(commentId: Int)
}

extension CommentService: PickeTargetType {
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


  public var method: HTTPMethod {
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
