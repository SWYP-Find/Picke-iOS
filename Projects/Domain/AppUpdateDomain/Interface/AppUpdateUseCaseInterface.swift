//
//  AppUpdateUseCaseInterface.swift
//  AppUpdateDomainInterface
//

import Foundation

import ComposableArchitecture

public protocol AppUpdateUseCaseInterface: Sendable {
  func checkForUpdate() async throws -> AppUpdateInfo?
}

public enum AppUpdateUseCaseDependency: TestDependencyKey {
  public static var testValue: AppUpdateUseCaseInterface { MockAppUpdateUseCase() }
}

public extension DependencyValues {
  var appUpdateUseCase: AppUpdateUseCaseInterface {
    get { self[AppUpdateUseCaseDependency.self] }
    set { self[AppUpdateUseCaseDependency.self] = newValue }
  }
}
