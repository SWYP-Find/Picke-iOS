import Alamofire
import API
import Foundation
import PickeNetwork

enum ClassTicketService {
  case preview(code: String)
  case register(code: String)
  case me
}

extension ClassTicketService: PickeDataRequest {
  var domain: any PickeDomainType { ClassTicketDomain() }

  var path: String {
    switch self {
    case .preview: return "class-tickets/preview"
    case .register: return "class-tickets/register"
    case .me: return "class-tickets/me"
    }
  }

  var method: HTTPMethod {
    switch self {
    case .preview, .me: return .get
    case .register: return .post
    }
  }

  var parameters: (any Encodable & Sendable)? {
    switch self {
    case let .preview(code): return ClassTicketCodeRequest(code: code)
    case let .register(code): return ClassTicketCodeRequest(code: code)
    case .me: return nil
    }
  }
}

private struct ClassTicketDomain: PickeDomainType {
  var baseURLString: String { PieckeDomain.battle.baseURLString }
  var url: String { "api/v1/" }
}

private struct ClassTicketCodeRequest: Encodable, Sendable {
  let code: String
}
