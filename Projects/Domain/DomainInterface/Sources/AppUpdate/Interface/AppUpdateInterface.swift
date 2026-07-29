//
//  AppUpdateInterface.swift
//  DomainInterface
//

import Foundation

import Entity
import WeaveDI

public protocol AppUpdateInterface: Sendable {
  func checkForUpdate() async throws -> AppUpdateInfo
}

public struct AppUpdateRepositoryDependency: DependencyKey {
  public static var liveValue: AppUpdateInterface {
    UnifiedDI.resolve(AppUpdateInterface.self) ?? DefaultAppUpdateRepositoryImpl()
  }

  public static var testValue: AppUpdateInterface {
    UnifiedDI.resolve(AppUpdateInterface.self) ?? DefaultAppUpdateRepositoryImpl()
  }

  public static var previewValue: AppUpdateInterface = liveValue
}

public extension DependencyValues {
  var appUpdateRepository: AppUpdateInterface {
    get { self[AppUpdateRepositoryDependency.self] }
    set { self[AppUpdateRepositoryDependency.self] = newValue }
  }
}
