import Alamofire
import API
import PickeNetwork

public enum ClassResultService {
  case result(Int)
  case myReport(Int)
  case insight(Int)
  case retryInsight(Int)
}

extension ClassResultService: PickeDataRequest {
  public var domain: any PickeDomainType {
    PieckeDomain.classroom
  }

  public var path: String {
    switch self {
    case let .result(id): return ClassResultAPI.result(classID: id).description
    case let .myReport(id): return ClassResultAPI.myReport(classID: id).description
    case let .insight(id): return ClassResultAPI.insight(classID: id).description
    case let .retryInsight(id): return ClassResultAPI.retryInsight(classID: id).description
    }
  }

  public var method: HTTPMethod {
    switch self {
    case .result, .myReport, .insight: return .get
    case .retryInsight: return .post
    }
  }

  public var parameters: (any Encodable & Sendable)? {
    nil
  }
}
