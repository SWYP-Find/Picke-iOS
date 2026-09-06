//
//  PerspectiveService.swift
//  Service
//

import Foundation

import API
import APIEndpoint
import NetworkHeader

public struct PerspectiveCommentBody: Encodable {
  public let content: String
  public init(content: String) { self.content = content }
}

public enum PerspectiveService {
  case detail(perspectiveId: Int)
  case listLabeledComments(perspectiveId: Int, cursor: String?, size: Int?)
  case createComment(perspectiveId: Int, body: PerspectiveCommentBody)
  case updateComment(perspectiveId: Int, commentId: Int, body: PerspectiveCommentBody)
  case deleteComment(perspectiveId: Int, commentId: Int)
  case updatePerspective(perspectiveId: Int, body: PerspectiveCommentBody)
  case deletePerspective(perspectiveId: Int)
  case likePerspective(perspectiveId: Int)
  case unlikePerspective(perspectiveId: Int)
  case fetchPerspectiveLikes(perspectiveId: Int)
  case reportPerspective(perspectiveId: Int)
  case reportComment(perspectiveId: Int, commentId: Int)
}

extension PerspectiveService: PickeTargetType {
  public typealias Domain = PieckeDomain

  public var domain: PieckeDomain { .perspective }

  public var urlPath: String {
    switch self {
    case let .detail(perspectiveId):
      return PerspectiveAPI.detail(perspectiveId: perspectiveId).description
    case let .listLabeledComments(perspectiveId, _, _):
      return PerspectiveAPI.listLabeledComments(perspectiveId: perspectiveId).description
    case let .createComment(perspectiveId, _):
      return PerspectiveAPI.createComment(perspectiveId: perspectiveId).description
    case let .updateComment(perspectiveId, commentId, _):
      return PerspectiveAPI.updateComment(perspectiveId: perspectiveId, commentId: commentId).description
    case let .deleteComment(perspectiveId, commentId):
      return PerspectiveAPI.deleteComment(perspectiveId: perspectiveId, commentId: commentId).description
    case let .updatePerspective(perspectiveId, _):
      return PerspectiveAPI.detail(perspectiveId: perspectiveId).description
    case let .deletePerspective(perspectiveId):
      return PerspectiveAPI.detail(perspectiveId: perspectiveId).description
    case let .likePerspective(perspectiveId):
      return PerspectiveAPI.likes(perspectiveId: perspectiveId).description
    case let .unlikePerspective(perspectiveId):
      return PerspectiveAPI.likes(perspectiveId: perspectiveId).description
    case let .fetchPerspectiveLikes(perspectiveId):
      return PerspectiveAPI.likes(perspectiveId: perspectiveId).description
    case let .reportPerspective(perspectiveId):
      return PerspectiveAPI.reports(perspectiveId: perspectiveId).description
    case let .reportComment(perspectiveId, commentId):
      return PerspectiveAPI.reportComment(perspectiveId: perspectiveId, commentId: commentId).description
    }
  }


  public var method: HTTPMethod {
    switch self {
    case .detail, .listLabeledComments, .fetchPerspectiveLikes:
      return .get
    case .createComment, .likePerspective, .reportPerspective, .reportComment:
      return .post
    case .updateComment, .updatePerspective:
      return .patch
    case .deleteComment, .deletePerspective, .unlikePerspective:
      return .delete
    }
  }

  public var parameters: [String: Any]? {
    switch self {
    case .detail:
      return nil
    case let .listLabeledComments(_, cursor, size):
      var query: [String: Any] = [:]
      if let cursor { query["cursor"] = cursor }
      if let size { query["size"] = size }
      return query.isEmpty ? nil : query
    case let .createComment(_, body):
      return body.toDictionary
    case let .updateComment(_, _, body):
      return body.toDictionary
    case let .updatePerspective(_, body):
      return body.toDictionary
    case .deleteComment:
      return nil
    case .deletePerspective:
      return nil
    case .likePerspective, .unlikePerspective, .fetchPerspectiveLikes:
      return nil
    case .reportPerspective, .reportComment:
      return nil
    }
  }

  public var headers: [String: String]? {
    APIHeader.baseHeader
  }
}
