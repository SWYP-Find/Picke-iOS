//
//  DefaultAppUpdateRepositoryImpl.swift
//  DomainInterface
//

import Foundation

import Entity

public final class DefaultAppUpdateRepositoryImpl: AppUpdateInterface {
  public init() {}

  public func checkForUpdate() async throws -> AppUpdateInfo {
    let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    return AppUpdateInfo(
      currentVersion: currentVersion,
      latestVersion: currentVersion,
      releaseNotes: nil,
      appStoreUrl: "https://apps.apple.com",
      isUpdateAvailable: false
    )
  }
}
