import Foundation

import AdDomainInterface

struct FeedAdDTO: Decodable, Sendable {
  let code: String
  let network: String
  let title: String
  let subtitle: String
  let imageURL: String
  let ctaText: String
  let clickURL: String
  let label: String

  // 서버는 imageUrl·clickUrl 로 내려준다. 프로퍼티명은 Swift 규약(URL 약어 대문자)에 맞춘다.
  enum CodingKeys: String, CodingKey {
    case code, network, title, subtitle, ctaText, label
    case imageURL = "imageUrl"
    case clickURL = "clickUrl"
  }

  /// imageURL·clickURL 이 URL 로 해석되지 않는 광고는 노출·클릭 모두 불가능하므로 버린다.
  func toDomain() -> FeedAd? {
    guard let imageURL = URL(string: imageURL), let clickURL = URL(string: clickURL) else {
      return nil
    }
    return FeedAd(
      code: code,
      network: network,
      title: title,
      subtitle: subtitle,
      imageURL: imageURL,
      ctaText: ctaText,
      clickURL: clickURL,
      label: label
    )
  }
}
