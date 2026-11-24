import ClassDomainInterface
import Foundation

struct ClassMemberDTO: Decodable, Sendable {
  let memberId: Int
  let displayName: String
  let role: String
  let characterUrl: URL?
  let me: Bool
}
