import Alamofire
import API
import ClassDomainInterface
import Foundation
import PickeCoreUtility
import PickeNetwork

enum ClassroomService {
  case myClasses
  case create(ClassCreation)
  case detail(Int)
  case updateDeadline(id: Int, deadline: Date)
  case delete(Int)
  case joinPreview(String)
  case join(code: String, nickname: String)
  case leave(Int)
}

extension ClassroomService: PickeDataRequest {
  var domain: any PickeDomainType { ClassroomDomain() }

  var path: String {
    switch self {
    case .myClasses, .create:
      return "classes"
    case let .detail(id), let .delete(id), let .updateDeadline(id, _):
      return "classes/\(id)"
    case .joinPreview:
      return "classes/join/preview"
    case .join:
      return "classes/join"
    case let .leave(id):
      return "classes/\(id)/members/me"
    }
  }

  var method: HTTPMethod {
    switch self {
    case .myClasses, .detail, .joinPreview: return .get
    case .create, .join: return .post
    case .updateDeadline: return .patch
    case .delete, .leave: return .delete
    }
  }

  var parameters: (any Encodable & Sendable)? {
    switch self {
    case let .create(creation):
      return CreateClassBody(creation: creation)
    case let .updateDeadline(_, deadline):
      return UpdateClassBody(deadline: deadline.formatted(.serverDateTime))
    case let .joinPreview(code):
      return ClassJoinPreviewQuery(inviteCode: code)
    case let .join(code, nickname):
      return JoinClassBody(inviteCode: code, displayName: nickname)
    case .myClasses, .detail, .delete, .leave:
      return nil
    }
  }
}

private struct ClassroomDomain: PickeDomainType {
  var baseURLString: String { PieckeDomain.battle.baseURLString }
  var url: String { "api/v1/" }
}

private struct CreateClassBody: Encodable, Sendable {
  let name: String
  let battleId: Int?
  let topicVersionId: Int?
  let deadline: String?
  let commentRequired: Bool
  let ownerParticipates: Bool

  init(creation: ClassCreation) {
    name = creation.name
    battleId = creation.battleId
    topicVersionId = creation.topicVersionId
    deadline = creation.deadline == .distantFuture
      ? nil
      : creation.deadline.formatted(.serverDateTime)
    commentRequired = creation.requiresComment
    ownerParticipates = creation.ownerParticipates
  }
}

private struct UpdateClassBody: Encodable, Sendable {
  let deadline: String
}

private struct ClassJoinPreviewQuery: Encodable, Sendable {
  let inviteCode: String
}

private struct JoinClassBody: Encodable, Sendable {
  let inviteCode: String
  let displayName: String
}
