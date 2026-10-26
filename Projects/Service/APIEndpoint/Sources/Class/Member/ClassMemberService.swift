import Alamofire
import API
import Foundation
import PickeNetwork

public enum ClassMemberService {
  case members(classID: Int)
  case updateMyName(classID: Int, name: String)
  case remove(classID: Int, memberID: Int)
}

extension ClassMemberService: PickeDataRequest {
  public var domain: any PickeDomainType {
    PieckeDomain.classroom
  }

  public var path: String {
    switch self {
    case let .members(classID): return ClassMemberAPI.members(classID: classID).description
    case let .updateMyName(classID, _): return ClassMemberAPI.me(classID: classID).description
    case let .remove(classID, memberID):
      return ClassMemberAPI.member(classID: classID, memberID: memberID).description
    }
  }

  public var method: HTTPMethod {
    switch self {
    case .members: return .get
    case .updateMyName: return .patch
    case .remove: return .delete
    }
  }

  public var parameters: (any Encodable & Sendable)? {
    switch self {
    case .members, .remove: return nil
    case let .updateMyName(_, name): return ClassMemberNameBody(displayName: name)
    }
  }
}
