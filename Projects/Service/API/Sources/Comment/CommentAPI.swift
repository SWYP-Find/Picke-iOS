//
//  CommentAPI.swift
//  API
//

import Foundation

public enum CommentAPI {
  case like(commentId: Int)
  case unlike(commentId: Int)

  public var description: String {
    switch self {
    case let .like(commentId):
      "\(commentId)/likes"
    case let .unlike(commentId):
      "\(commentId)/likes"
    }
  }
}
