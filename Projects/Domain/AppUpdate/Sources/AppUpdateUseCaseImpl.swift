//
//  AppUpdateUseCaseImpl.swift
//  AppUpdateDomain
//

import AppUpdateDomainInterface

import ComposableArchitecture

public struct AppUpdateUseCaseImpl: AppUpdateUseCaseInterface {
  @Dependency(\.appUpdateRepository) var repository

  public init() {}

  public func checkForUpdate() async throws -> AppUpdateInfo? {
    let updateInfo = try await repository.checkForUpdate()
    return updateInfo.isUpdateAvailable ? updateInfo : nil
  }
}
