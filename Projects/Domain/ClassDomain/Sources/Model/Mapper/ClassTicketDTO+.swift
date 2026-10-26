import ClassDomainInterface
import Foundation
import PickeCoreUtility

extension ClassTicketDTO {
  func toDomain() throws -> ClassTicket {
    guard
      let status = ClassTicket.Status(rawValue: status),
      let activatedAt = ServerDateParser.parse(activatedAt),
      let expiresAt = ServerDateParser.parse(expiresAt),
      let readGraceEndsAt = ServerDateParser.parse(readGraceEndsAt)
    else { throw ClassTicketError.invalidResponse }

    return ClassTicket(
      id: ticketId,
      capacity: capacity,
      status: status,
      activatedAt: activatedAt,
      expiresAt: expiresAt,
      remainingDays: remainingDays,
      readGraceEndsAt: readGraceEndsAt
    )
  }
}
