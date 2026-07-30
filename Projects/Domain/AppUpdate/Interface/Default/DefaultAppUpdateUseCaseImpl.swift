//
//  DefaultAppUpdateUseCaseImpl.swift
//  AppUpdateDomain
//

import Foundation

import AppUpdateDomainInterface

public struct DefaultAppUpdateUseCaseImpl: AppUpdateUseCaseInterface {
  public init() {}

  public func checkForUpdate() async throws -> AppUpdateInfo? {
    nil
  }
}
