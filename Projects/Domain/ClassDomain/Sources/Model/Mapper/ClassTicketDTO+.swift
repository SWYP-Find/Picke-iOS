import ClassDomainInterface
import Foundation
import PickeCoreUtility

extension ClassTicketDTO {
  func toDomain() throws -> ClassTicket {
    // Android `ClassTicketStatus.from`과 같이 모르는 상태값은 만료로 본다.
    let status = ClassTicket.Status(rawValue: self.status) ?? .expired
    guard
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
