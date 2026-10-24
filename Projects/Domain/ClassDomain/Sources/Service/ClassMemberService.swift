import Alamofire
import API
import Foundation
import PickeNetwork

enum ClassMemberService {
  case members(classID: Int)
  case updateMyName(classID: Int, name: String)
  case remove(classID: Int, memberID: Int)
}

extension ClassMemberService: PickeDataRequest {
  var domain: any PickeDomainType {
    ClassMemberDomain()
  }

  var path: String {
    switch self {
    case let .members(classID): return "classes/\(classID)/members"
    case let .updateMyName(classID, _): return "classes/\(classID)/members/me"
    case let .remove(classID, memberID): return "classes/\(classID)/members/\(memberID)"
    }
  }

  var method: HTTPMethod {
    switch self {
    case .members: return .get
    case .updateMyName: return .patch
    case .remove: return .delete
    }
  }

  var parameters: (any Encodable & Sendable)? {
    switch self {
    case .members, .remove: return nil
    case let .updateMyName(_, name): return ClassMemberNameBody(displayName: name)
    }
  }
}

private struct ClassMemberDomain: PickeDomainType {
  var baseURLString: String {
    PieckeDomain.battle.baseURLString
  }

  var url: String {
    "api/v1/"
  }
}

private struct ClassMemberNameBody: Encodable, Sendable {
  let displayName: String
}
