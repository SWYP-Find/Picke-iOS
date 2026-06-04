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
  case likes(perspectiveId: Int)
  case reports(perspectiveId: Int)
  case reportComment(perspectiveId: Int, commentId: Int)

  public var description: String {
    switch self {
    case let .detail(perspectiveId):
      return "\(perspectiveId)"
    case let .likes(perspectiveId):
      return "\(perspectiveId)/likes"
    case let .reports(perspectiveId):
      return "\(perspectiveId)/reports"
    case let .reportComment(perspectiveId, commentId):
      return "\(perspectiveId)/comments/\(commentId)/reports"
    case let .listLabeledComments(perspectiveId):
      return "\(perspectiveId)/comments/labeled"
    case let .createComment(perspectiveId):
      return "\(perspectiveId)/comments"
    case let .updateComment(perspectiveId, commentId):
      return "\(perspectiveId)/comments/\(commentId)"
    case let .deleteComment(perspectiveId, commentId):
      return "\(perspectiveId)/comments/\(commentId)"
    }
  }
}
