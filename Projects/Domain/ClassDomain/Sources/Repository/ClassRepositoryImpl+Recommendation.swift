import APIEndpoint
import ClassDomainInterface
import Foundation
import PickeNetwork

extension ClassRepositoryImpl {
  public func fetchRecommendedBattles(filter: ClassTopicFilter) async throws -> [ClassBattleSummary] {
    guard (1 ... 3).contains(filter.categories.count), filter.keyword.count <= 50 else {
      throw ClassError.unknown("추천 조건을 확인해 주세요.")
    }
    do {
      let data = try await client.send(
        ClassBattleRecommendationService.recommendations(filter: filter),
        as: ClassBattleRecommendationDataDTO.self
      )
      return try data.items.map { try $0.toDomain() }
    } catch let error as PickeNetworkError {
      if case let .response(response) = error {
        throw ClassError.network(response.message ?? "배틀 추천을 불러오지 못했습니다.")
      }
      throw ClassError.from(error)
    }
  }

}
