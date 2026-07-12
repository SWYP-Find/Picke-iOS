//
//  AppUpdateUseCaseInterface.swift
//  DomainInterface
//
//  앱 업데이트 체크 UseCase 인터페이스 + 의존성 등록.
//  구현(AppUpdateUseCaseImpl)은 UseCase 모듈에 유지하고 DI 로 주입한다.
//

import Foundation

import Entity
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
