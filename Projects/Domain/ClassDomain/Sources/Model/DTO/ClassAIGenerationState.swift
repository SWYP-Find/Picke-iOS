import Foundation

enum ClassAIGenerationState: Decodable, Equatable, Sendable {
  case beforeClose
  case pending
  case generating
  case succeeded
  case limited
  case notEligible
  case failed
  case unknown

  init(from decoder: Decoder) throws {
    let value = try decoder.singleValueContainer().decode(String.self)
    switch value {
    case "BEFORE_CLOSE": self = .beforeClose
    case "PENDING": self = .pending
    case "GENERATING": self = .generating
    case "SUCCEEDED": self = .succeeded
    case "LIMITED": self = .limited
    case "NOT_ELIGIBLE": self = .notEligible
    case "FAILED": self = .failed
    default: self = .unknown
    }
  }
}
