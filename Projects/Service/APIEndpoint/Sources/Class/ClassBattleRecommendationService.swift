import Alamofire
import API
import ClassDomainInterface
import Foundation
import PickeNetwork

public enum ClassBattleRecommendationService {
  case recommendations(filter: ClassTopicFilter)
}

extension ClassBattleRecommendationService: PickeDataRequest {
  public var domain: any PickeDomainType {
    PieckeDomain.classroom
  }

  public var path: String {
    ClassBattleRecommendationAPI.recommendations.description
  }

  public var method: HTTPMethod {
    .get
  }

  public var parameters: (any Encodable & Sendable)? {
    switch self {
    case let .recommendations(filter):
      return ClassBattleRecommendationQuery(
        difficulty: filter.level.apiValue,
        categories: filter.categories.map(\.title).joined(separator: ","),
        keyword: filter.keyword.isEmpty ? nil : filter.keyword
      )
    }
  }
}

private extension ClassAudienceLevel {
  var apiValue: String {
    switch self {
    case .middle: return "BEGINNER"
    case .high: return "INTERMEDIATE"
    case .adult: return "ADVANCED"
    }
  }
}
