//
//  PerspectiveAPI.swift
//  API
//

import Foundation

public enum PerspectiveAPI {
  case detail(perspectiveId: Int)
  case listLabeledComments(perspectiveId: Int)
  case createComment(perspectiveId: Int)
  case updateComment(perspectiveId: Int, commentId: Int)
  case deleteComment(perspectiveId: Int, commentId: Int)

  public var description: String {
    switch self {
    case let .detail(perspectiveId):
      "\(perspectiveId)"
    case let .listLabeledComments(perspectiveId):
      "\(perspectiveId)/comments/labeled"
    case let .createComment(perspectiveId):
      "\(perspectiveId)/comments"
    case let .updateComment(perspectiveId, commentId):
      "\(perspectiveId)/comments/\(commentId)"
    case let .deleteComment(perspectiveId, commentId):
      "\(perspectiveId)/comments/\(commentId)"
    }
  }
}
