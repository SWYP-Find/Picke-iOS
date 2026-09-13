import Foundation

public struct AdsQueryRequest: Encodable, Sendable {
  public let slot: AdSlot
  public let os: String
  public let size: Int

  public init(
    slot: AdSlot = .homeFeed,
    os: String = "IOS",
    size: Int = 20
  ) {
    self.slot = slot
    self.os = os
    self.size = size
  }
}
