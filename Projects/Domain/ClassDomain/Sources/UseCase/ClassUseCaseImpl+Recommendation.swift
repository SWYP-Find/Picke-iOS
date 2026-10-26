//
//  ClassUseCaseImpl+Recommendation.swift
//  ClassDomain
//
//  Created by Picke on 10/26/26.
//

import ClassDomainInterface
import Foundation

extension ClassUseCaseImpl {
  public func fetchRecommendedBattles(filter: ClassTopicFilter) async throws -> [ClassBattleSummary] {
    try await repository.fetchRecommendedBattles(filter: filter)
  }
}
