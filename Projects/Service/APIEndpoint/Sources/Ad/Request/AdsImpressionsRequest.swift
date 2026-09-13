import Foundation

public struct AdsImpressionsRequest: Encodable, Sendable {
  public let codes: [String]

  public init(codes: [String]) {
    self.codes = codes
  }
}
