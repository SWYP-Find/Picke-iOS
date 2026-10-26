import Alamofire
import API
import ClassDomainInterface
import Foundation
import PickeCoreUtility
import PickeNetwork

public enum ClassroomService {
  case myClasses
  case create(ClassCreation)
  case detail(Int)
  case updateDeadline(id: Int, deadline: Date)
  case updateName(id: Int, name: String)
  case delete(Int)
  case joinPreview(String)
  case join(code: String, nickname: String)
  case leave(Int)
}

extension ClassroomService: PickeDataRequest {
  public var domain: any PickeDomainType { PieckeDomain.classroom }

  public var path: String {
    switch self {
    case .myClasses, .create:
      return ClassroomAPI.classes.description
    case let .detail(id), let .delete(id), let .updateDeadline(id, _), let .updateName(id, _):
      return ClassroomAPI.detail(classID: id).description
    case .joinPreview:
      return ClassroomAPI.joinPreview.description
    case .join:
      return ClassroomAPI.join.description
    case let .leave(id):
      return ClassroomAPI.leave(classID: id).description
    }
  }

  public var method: HTTPMethod {
    switch self {
    case .myClasses, .detail, .joinPreview: return .get
    case .create, .join: return .post
    case .updateDeadline, .updateName: return .patch
    case .delete, .leave: return .delete
    }
  }

  public var parameters: (any Encodable & Sendable)? {
    switch self {
    case let .create(creation):
      return CreateClassBody(creation: creation)
    case let .updateDeadline(_, deadline):
      return UpdateClassBody(name: nil, deadline: deadline.formatted(.serverDateTime))
    case let .updateName(_, name):
      return UpdateClassBody(name: name, deadline: nil)
    case let .joinPreview(code):
      return ClassJoinPreviewQuery(inviteCode: code)
    case let .join(code, nickname):
      return JoinClassBody(inviteCode: code, displayName: nickname)
    case .myClasses, .detail, .delete, .leave:
      return nil
    }
  }
}
