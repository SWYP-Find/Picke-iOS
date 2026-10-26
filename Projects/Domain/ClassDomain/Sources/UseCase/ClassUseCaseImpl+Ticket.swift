//
//  ClassUseCaseImpl+Ticket.swift
//  ClassDomain
//
//  Created by Picke on 10/26/26.
//

import ClassDomainInterface
import Foundation

extension ClassUseCaseImpl {
  public func previewTicket(code: String) async throws -> ClassTicketPreview {
    try await repository.previewTicket(code: code)
  }

  public func registerTicket(code: String) async throws -> ClassTicket {
    try await repository.registerTicket(code: code)
  }

  public func fetchMyTicket() async throws -> ClassTicket {
    try await repository.fetchMyTicket()
  }
}
