//
//  DefaultAppUpdateUseCaseImpl.swift
//  DomainInterface
//
//  AppUpdate UseCase 미해결 시 fallback (업데이트 없음).
//

import Foundation

import Entity

public struct DefaultAppUpdateUseCaseImpl: AppUpdateUseCaseInterface {
  public init() {}

  public func checkForUpdate() async throws -> AppUpdateInfo? {
    nil
  }
}
