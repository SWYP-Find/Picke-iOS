import ComposableArchitecture
import Foundation

public protocol ClassRecommendationInterface: Sendable {
  func fetchRecommendedBattles(filter: ClassTopicFilter) async throws -> [ClassBattleSummary]
}

public enum ClassRecommendationRepositoryDependency: TestDependencyKey {
  public static var testValue: any ClassRecommendationInterface {
    MockClassRepository()
  }
}

public enum ClassRecommendationUseCaseDependency: TestDependencyKey {
  public static var testValue: any ClassRecommendationInterface {
    MockClassRepository()
  }
}

public extension DependencyValues {
  var classRecommendationRepository: any ClassRecommendationInterface {
    get { self[ClassRecommendationRepositoryDependency.self] }
    set { self[ClassRecommendationRepositoryDependency.self] = newValue }
  }

  var classRecommendationUseCase: any ClassRecommendationInterface {
    get { self[ClassRecommendationUseCaseDependency.self] }
    set { self[ClassRecommendationUseCaseDependency.self] = newValue }
  }
}
