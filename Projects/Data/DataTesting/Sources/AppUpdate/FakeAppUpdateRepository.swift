//
//  FakeAppUpdateRepository.swift
//  DataTesting
//
//  AppUpdateInterface(Repository) 의 재사용 가능한 페이크.
//  지정한 결과를 그대로 반환한다(네트워크 미접근).
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
