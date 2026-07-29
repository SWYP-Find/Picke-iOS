//
//  FakeAppUpdateRepository.swift
//  DataTesting
//

import DomainInterface
import Entity

public struct FakeAppUpdateRepository: AppUpdateInterface {
  public var info: AppUpdateInfo

  public init(info: AppUpdateInfo) {
    self.info = info
  }

  public func checkForUpdate() async throws -> AppUpdateInfo {
    info
  }
}
