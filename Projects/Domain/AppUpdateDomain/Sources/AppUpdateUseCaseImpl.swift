//
//  AppUpdateUseCaseImpl.swift
//  AppUpdateDomain
//
//  Created by Picke on 10/11/26.
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
