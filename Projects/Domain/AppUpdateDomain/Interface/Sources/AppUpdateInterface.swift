//
//  AppUpdateInterface.swift
//  AppUpdateDomainInterface
//

import Foundation

import ComposableArchitecture

public protocol AppUpdateInterface: Sendable {
  func checkForUpdate() async throws -> AppUpdateInfo
}

public enum AppUpdateRepositoryDependency: TestDependencyKey {
  public static var testValue: AppUpdateInterface { MockAppUpdateRepository() }
}

public extension DependencyValues {
  var appUpdateRepository: AppUpdateInterface {
    get { self[AppUpdateRepositoryDependency.self] }
    set { self[AppUpdateRepositoryDependency.self] = newValue }
  }
}
