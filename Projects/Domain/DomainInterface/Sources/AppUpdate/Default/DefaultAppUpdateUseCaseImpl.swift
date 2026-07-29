//
//  DefaultAppUpdateUseCaseImpl.swift
//  DomainInterface
//

import Foundation

import Entity

public struct DefaultAppUpdateUseCaseImpl: AppUpdateUseCaseInterface {
  public init() {}

  public func checkForUpdate() async throws -> AppUpdateInfo? {
    nil
  }
}
