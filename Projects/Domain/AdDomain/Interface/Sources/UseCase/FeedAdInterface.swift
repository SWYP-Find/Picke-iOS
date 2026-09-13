import ComposableArchitecture

public protocol FeedAdInterface: Sendable {
  func fetchAds() async throws -> [FeedAd]
  func recordImpressions(codes: [String]) async throws
}

public enum FeedAdUseCaseDependency: TestDependencyKey {
  public static var testValue: FeedAdInterface { MockFeedAdClient() }
}

public enum FeedAdRepositoryDependency: TestDependencyKey {
  public static var testValue: FeedAdInterface { MockFeedAdClient() }
}

public extension DependencyValues {
  var feedAdRepository: FeedAdInterface {
    get { self[FeedAdRepositoryDependency.self] }
    set { self[FeedAdRepositoryDependency.self] = newValue }
  }

  var feedAdUseCase: FeedAdInterface {
    get { self[FeedAdUseCaseDependency.self] }
    set { self[FeedAdUseCaseDependency.self] = newValue }
  }
}

private struct MockFeedAdClient: FeedAdInterface {
  func fetchAds() async throws -> [FeedAd] { [] }
  func recordImpressions(codes: [String]) async throws {}
}
