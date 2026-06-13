//
//  AppUpdateUseCaseImpl.swift
//  UseCase
//
//  앱 업데이트 체크 — 업데이트가 필요한 경우에만 정보 반환.
//

import DomainInterface
import Entity

import ComposableArchitecture

public protocol AppUpdateUseCaseInterface: Sendable {
  func checkForUpdate() async throws -> AppUpdateInfo?
}

public struct AppUpdateUseCaseImpl: AppUpdateUseCaseInterface {
  @Dependency(\.appUpdateRepository) var repository

  public init() {}

  public func checkForUpdate() async throws -> AppUpdateInfo? {
    let updateInfo = try await repository.checkForUpdate()
    return updateInfo.isUpdateAvailable ? updateInfo : nil
  }
}

extension AppUpdateUseCaseImpl: DependencyKey {
  public static var liveValue: AppUpdateUseCaseInterface = AppUpdateUseCaseImpl()
  public static var testValue: AppUpdateUseCaseInterface = AppUpdateUseCaseImpl()
  public static var previewValue: AppUpdateUseCaseInterface = liveValue
}

public extension DependencyValues {
  var appUpdateUseCase: AppUpdateUseCaseInterface {
    get { self[AppUpdateUseCaseImpl.self] }
    set { self[AppUpdateUseCaseImpl.self] = newValue }
  }
}
