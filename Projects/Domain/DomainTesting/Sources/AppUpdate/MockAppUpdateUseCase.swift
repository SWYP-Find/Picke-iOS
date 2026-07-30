//
//  MockAppUpdateUseCase.swift
//  DomainTesting
//

import AppUpdateDomainInterface

public struct MockAppUpdateUseCase: AppUpdateUseCaseInterface {
  public var info: AppUpdateInfo?

  public init(info: AppUpdateInfo? = nil) {
    self.info = info
  }

  public func checkForUpdate() async throws -> AppUpdateInfo? {
    info
  }
}
