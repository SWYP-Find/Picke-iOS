import Foundation

public struct FeedAd: Equatable, Sendable, Identifiable {
  public let code: String
  public let network: String
  public let title: String
  public let subtitle: String
  public let imageURL: URL
  public let ctaText: String
  public let clickURL: URL
  public let label: String

  public var id: String { code }

  public init(
    code: String,
    network: String,
    title: String,
    subtitle: String,
    imageURL: URL,
    ctaText: String,
    clickURL: URL,
    label: String
  ) {
    self.code = code
    self.network = network
    self.title = title
    self.subtitle = subtitle
    self.imageURL = imageURL
    self.ctaText = ctaText
    self.clickURL = clickURL
    self.label = label
  }
}
