//
//  AppUpdateUseCaseInterface.swift
//  AppUpdateDomainInterface
//

import Foundation

import WeaveDI

public protocol AppUpdateUseCaseInterface: Sendable {
  func checkForUpdate() async throws -> AppUpdateInfo?
}

public struct AppUpdateUseCaseDependency: DependencyKey {
  public static var liveValue: AppUpdateUseCaseInterface {
    UnifiedDI.resolve(AppUpdateUseCaseInterface.self) ?? DefaultAppUpdateUseCaseImpl()
  }

  public static var testValue: AppUpdateUseCaseInterface {
    UnifiedDI.resolve(AppUpdateUseCaseInterface.self) ?? DefaultAppUpdateUseCaseImpl()
  }

  public static var previewValue: AppUpdateUseCaseInterface = liveValue
}

public extension DependencyValues {
  var appUpdateUseCase: AppUpdateUseCaseInterface {
    get { self[AppUpdateUseCaseDependency.self] }
    set { self[AppUpdateUseCaseDependency.self] = newValue }
  }
}
