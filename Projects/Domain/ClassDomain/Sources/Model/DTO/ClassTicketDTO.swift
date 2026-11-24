import ClassDomainInterface
import Foundation
import PickeCoreUtility

struct ClassTicketDTO: Decodable, Sendable {
  let ticketId: Int
  let capacity: Int
  let status: String
  let activatedAt: String
  let expiresAt: String
  let remainingDays: Int
  let readGraceEndsAt: String
}
