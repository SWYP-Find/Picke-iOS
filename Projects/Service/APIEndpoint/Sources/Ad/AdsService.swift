import Foundation
import Alamofire
import API
import PickeNetwork

public enum AdsService {
  case list(query: AdsQueryRequest)
  case impressions(body: AdsImpressionsRequest)
}

extension AdsService: PickeDataRequest {
  public var domain: any PickeDomainType { PieckeDomain.ads }

  public var path: String {
    switch self {
    case .list:
      return AdsAPI.ads.description
    case .impressions:
      return AdsAPI.impressions.description
    }
  }

  public var method: HTTPMethod {
    switch self {
    case .list: return .get
    case .impressions: return .post
    }
  }

  public var parameters: (any Encodable & Sendable)? {
    switch self {
    case let .list(query): return query
    case let .impressions(body): return body
    }
  }
}
