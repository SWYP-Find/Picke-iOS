import Alamofire
import API
import ClassDomainInterface
import Foundation
import PickeNetwork

enum ClassBattleRecommendationService {
  case recommendations(filter: ClassTopicFilter)
}

extension ClassBattleRecommendationService: PickeDataRequest {
  var domain: any PickeDomainType {
    ClassBattleRecommendationDomain()
  }

  var path: String {
    "class-battle-recommendations"
  }

  var method: HTTPMethod {
    .get
  }

  var parameters: (any Encodable & Sendable)? {
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

private struct ClassBattleRecommendationDomain: PickeDomainType {
  var baseURLString: String {
    PieckeDomain.battle.baseURLString
  }

  var url: String {
    "api/v1/"
  }
}

private struct ClassBattleRecommendationQuery: Encodable, Sendable {
  let difficulty: String
  let categories: String
  let keyword: String?
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
