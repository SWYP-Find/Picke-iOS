import ClassDomainInterface
import Foundation
import PickeCoreUtility

struct ClassTicketPreviewDTO: Decodable, Sendable {
  let capacity: Int
  let registerBy: String
  let usageMonths: Int
  let registeredByMe: Bool
}
