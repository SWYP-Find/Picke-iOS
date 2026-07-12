//
//  MockAppUpdateUseCase.swift
//  DomainTesting
//
//  AppUpdateUseCaseInterface 의 재사용 가능한 테스트 스텁.
//  지정한 결과를 그대로 반환한다(네트워크 미접근).
//

import DomainInterface
import Entity
import UseCase

public struct MockAppUpdateUseCase: AppUpdateUseCaseInterface {
  public var info: AppUpdateInfo?

  public init(info: AppUpdateInfo? = nil) {
    self.info = info
  }

  public func checkForUpdate() async throws -> AppUpdateInfo? {
    info
  }
}
