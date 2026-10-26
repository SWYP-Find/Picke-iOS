import ClassDomainInterface
import Foundation

extension ClassUseCaseImpl {
  public func fetchRecommendedBattles(filter: ClassTopicFilter) async throws -> [ClassBattleSummary] {
    try await repository.fetchRecommendedBattles(filter: filter)
  }
}
