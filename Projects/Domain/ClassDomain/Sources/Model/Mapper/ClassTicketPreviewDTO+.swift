import ClassDomainInterface
import Foundation
import PickeCoreUtility

extension ClassTicketPreviewDTO {
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
