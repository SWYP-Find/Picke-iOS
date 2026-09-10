//
//  CommentService.swift
//  Service
//

import Foundation

import Alamofire
import API
import PickeNetwork

public enum CommentService {
  case like(commentId: Int)
  case unlike(commentId: Int)
}

extension CommentService: PickeDataRequest {
  public var domain: any PickeDomainType { PieckeDomain.comment }

  public var path: String {
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
}
