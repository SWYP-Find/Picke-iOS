import Alamofire
import API
import Foundation
import PickeNetwork

public enum ClassTicketService {
  case preview(code: String)
  case register(code: String)
  case me
}

extension ClassTicketService: PickeDataRequest {
  public var domain: any PickeDomainType { PieckeDomain.classroom }

  public var path: String {
    switch self {
    case .preview: return ClassTicketAPI.preview.description
    case .register: return ClassTicketAPI.register.description
    case .me: return ClassTicketAPI.me.description
    }
  }

  public var method: HTTPMethod {
    switch self {
    case .preview, .me: return .get
    case .register: return .post
    }
  }

  public var parameters: (any Encodable & Sendable)? {
    switch self {
    case let .preview(code): return ClassTicketCodeRequest(code: code)
    case let .register(code): return ClassTicketCodeRequest(code: code)
    case .me: return nil
    }
  }
}
