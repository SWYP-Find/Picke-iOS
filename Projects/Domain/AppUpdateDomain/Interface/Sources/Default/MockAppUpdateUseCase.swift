//
//  MockAppUpdateUseCase.swift
//  AppUpdateDomain
//

import Foundation

import AppUpdateDomainInterface

public struct MockAppUpdateUseCase: AppUpdateUseCaseInterface {
  public init() {}

  public func checkForUpdate() async throws -> AppUpdateInfo? {
    nil
  }
}
