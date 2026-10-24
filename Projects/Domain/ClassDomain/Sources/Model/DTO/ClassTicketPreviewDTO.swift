import ClassDomainInterface
import Foundation
import PickeCoreUtility

struct ClassTicketPreviewDTO: Decodable, Sendable {
  let capacity: Int
  let registerBy: String
  let usageMonths: Int
  let registeredByMe: Bool

  func toDomain() throws -> ClassTicketPreview {
    guard let date = ServerDateParser.parse(registerBy) else {
      throw ClassTicketError.invalidResponse
    }
    return ClassTicketPreview(
      capacity: capacity,
      registerBy: date,
      usageMonths: usageMonths,
      registeredByMe: registeredByMe
    )
  }
}
