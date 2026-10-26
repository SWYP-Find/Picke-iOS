//
//  ClassRepositoryImpl+Ticket.swift
//  ClassDomain
//
//  Created by Picke on 10/26/26.
//

import APIEndpoint
import ClassDomainInterface
import Foundation
import PickeNetwork

extension ClassRepositoryImpl {
  public func previewTicket(code: String) async throws -> ClassTicketPreview {
    do {
      let payload = try await client.send(ClassTicketService.preview(code: code), as: ClassTicketPreviewDTO.self)
      return try payload.toDomain()
    } catch {
      throw Self.ticketError(error)
    }
  }

  public func registerTicket(code: String) async throws -> ClassTicket {
    do {
      let payload = try await client.send(ClassTicketService.register(code: code), as: ClassTicketDTO.self)
      return try payload.toDomain()
    } catch {
      throw Self.ticketError(error)
    }
  }

  public func fetchMyTicket() async throws -> ClassTicket {
    do {
      let payload = try await client.send(ClassTicketService.me, as: ClassTicketDTO.self)
      return try payload.toDomain()
    } catch {
      throw Self.ticketError(error)
    }
  }

  static func ticketError(_ error: Error) -> ClassTicketError {
    if let error = error as? ClassTicketError { return error }
    if let error = error as? PickeNetworkError {
      if case let .response(response) = error {
        switch response.code {
        case "COMMON_400", "TICKET_404_CODE": return .invalidCode
        case "TICKET_409_REVOKED": return .revoked
        case "TICKET_409_REG_EXP": return .registrationExpired
        case "TICKET_409_CLAIMED": return .claimed
        case "TICKET_409_ACTIVE": return .activeTicket
        case "TICKET_404": return .notFound
        default: return .network(response.message ?? "이용권 정보를 불러오지 못했어요.")
        }
      }
    }
    return .network(error.localizedDescription)
  }
}
