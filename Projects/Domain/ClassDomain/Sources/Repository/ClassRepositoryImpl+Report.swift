//
//  ClassRepositoryImpl+Report.swift
//  ClassDomain
//
//  Created by Picke on 10/26/26.
//

import ClassDomainInterface
import Foundation

extension ClassRepositoryImpl {
  private static let unavailableMessage = "클래스 서버 API가 연결되지 않았습니다."

  public func fetchReport(roomID _: Int) async throws -> ClassReport? {
    throw ClassError.network(Self.unavailableMessage)
  }

  public func fetchOwnerDashboard(roomID _: Int) async throws -> ClassOwnerDashboardData? {
    throw ClassError.network(Self.unavailableMessage)
  }

}
