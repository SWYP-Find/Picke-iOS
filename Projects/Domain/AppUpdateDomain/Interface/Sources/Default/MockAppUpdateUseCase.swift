//
//  MockAppUpdateUseCase.swift
//  AppUpdateDomainInterface
//
//  Created by Picke on 10/11/26.
//

import Foundation

import AppUpdateDomainInterface

public struct MockAppUpdateUseCase: AppUpdateUseCaseInterface {
  public init() {}

  public func checkForUpdate() async throws -> AppUpdateInfo? {
    nil
  }
}
