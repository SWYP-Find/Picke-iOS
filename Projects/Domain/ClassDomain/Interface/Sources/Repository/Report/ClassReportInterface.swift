//
//  ClassReportInterface.swift
//  ClassDomainInterface
//
//  Created by Picke on 10/26/26.
//

import ComposableArchitecture
import Foundation

public protocol ClassReportInterface: Sendable {
  func fetchReport(roomID: Int) async throws -> ClassReport?
  func fetchOwnerDashboard(roomID: Int) async throws -> ClassOwnerDashboardData?
}

public enum ClassReportRepositoryDependency: TestDependencyKey {
  public static var testValue: any ClassReportInterface {
    MockClassRepository()
  }
}

public enum ClassReportUseCaseDependency: TestDependencyKey {
  public static var testValue: any ClassReportInterface {
    MockClassRepository()
  }
}

public extension DependencyValues {
  var classReportRepository: any ClassReportInterface {
    get { self[ClassReportRepositoryDependency.self] }
    set { self[ClassReportRepositoryDependency.self] = newValue }
  }

  var classReportUseCase: any ClassReportInterface {
    get { self[ClassReportUseCaseDependency.self] }
    set { self[ClassReportUseCaseDependency.self] = newValue }
  }
}
