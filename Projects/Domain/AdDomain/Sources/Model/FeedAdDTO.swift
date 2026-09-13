import AdDomainInterface

struct FeedAdDTO: Decodable, Sendable {
  let code: String
  let network: String
  let title: String
  let subtitle: String
  let imageUrl: String
  let ctaText: String
  let clickUrl: String
  let label: String

  func toDomain() -> FeedAd {
    FeedAd(
      code: code,
      network: network,
      title: title,
      subtitle: subtitle,
      imageURL: imageUrl,
      ctaText: ctaText,
      clickURL: clickUrl,
      label: label
    )
  }
}
