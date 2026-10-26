//
//  ClassUseCaseImpl+Report.swift
//  ClassDomain
//
//  Created by Picke on 10/26/26.
//

import ClassDomainInterface
import Foundation

extension ClassUseCaseImpl {
  public func fetchReport(roomID: Int) async throws -> ClassReport? {
    try await repository.fetchReport(roomID: roomID)
  }

  public func fetchOwnerDashboard(roomID: Int) async throws -> ClassOwnerDashboardData? {
    try await repository.fetchOwnerDashboard(roomID: roomID)
  }
}
