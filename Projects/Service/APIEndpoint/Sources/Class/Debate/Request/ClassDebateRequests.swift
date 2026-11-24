import Foundation

struct ReplyBody: Encodable, Sendable {
  let roundIndex: Int
  let content: String
  let requestKey: String
}
