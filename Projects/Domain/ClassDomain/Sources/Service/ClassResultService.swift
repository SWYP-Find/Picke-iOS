import Alamofire
import API
import PickeNetwork

enum ClassResultService {
  case result(Int)
  case myReport(Int)
  case insight(Int)
  case retryInsight(Int)
}

extension ClassResultService: PickeDataRequest {
  var domain: any PickeDomainType {
    ClassResultDomain()
  }

  var path: String {
    switch self {
    case let .result(id): return "classes/\(id)/result"
    case let .myReport(id): return "classes/\(id)/result/my-report"
    case let .insight(id): return "classes/\(id)/result/insight"
    case let .retryInsight(id): return "classes/\(id)/result/insight/retry"
    }
  }

  var method: HTTPMethod {
    switch self {
    case .result, .myReport, .insight: return .get
    case .retryInsight: return .post
    }
  }

  var parameters: (any Encodable & Sendable)? {
    nil
  }
}

private struct ClassResultDomain: PickeDomainType {
  var baseURLString: String {
    PieckeDomain.battle.baseURLString
  }

  var url: String {
    "api/v1/"
  }
}
