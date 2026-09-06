//
//  MockAppUpdateRepository.swift
//  AppUpdateDomain
//

import Foundation

import AppUpdateDomainInterface

public final class MockAppUpdateRepository: AppUpdateInterface {
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
