//
//  AppUpdateUseCaseImpl.swift
//  UseCase
//

import DomainInterface
import Entity

import ComposableArchitecture

public struct AppUpdateUseCaseImpl: AppUpdateUseCaseInterface {
  @Dependency(\.appUpdateRepository) var repository

  public init() {}

  public func checkForUpdate() async throws -> AppUpdateInfo? {
    let updateInfo = try await repository.checkForUpdate()
    return updateInfo.isUpdateAvailable ? updateInfo : nil
  }
}
