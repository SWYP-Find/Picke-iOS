import Foundation

struct VoteBody: Encodable, Sendable {
  let optionId: Int
}

struct PerspectiveBody: Encodable, Sendable {
  let content: String
}

struct PerspectivesQuery: Encodable, Sendable {
  let cursor: String?
  let size: Int?
  let optionId: Int?
  let sort: String?
}
