import AdDomainInterface
import ComposableArchitecture

public struct FeedAdUseCaseImpl: FeedAdInterface {
  @Dependency(\.feedAdRepository) private var feedAdRepository

  public init() {}

  public func fetchAds() async throws -> [FeedAd] {
    return try await feedAdRepository.fetchAds()
  }

  public func recordImpressions(codes: [String]) async throws {
    try await feedAdRepository.recordImpressions(codes: codes)
  }
}
