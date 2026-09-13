import APIEndpoint
import AdDomainInterface
import ComposableArchitecture
import PickeNetwork

public struct FeedAdRepositoryImpl: FeedAdInterface {
  @Dependency(\.networkClient) private var client

  public init() {}

  public func fetchAds() async throws -> [FeedAd] {
    let data = try await client.send(
      AdsService.list(query: AdsQueryRequest()),
      as: [FeedAdDTO].self
    )
    return data.map { $0.toDomain() }
  }

  public func recordImpressions(codes: [String]) async throws {
    _ = try await client.send(
      AdsService.impressions(body: AdsImpressionsRequest(codes: codes)),
      as: String.self
    )
  }
}
