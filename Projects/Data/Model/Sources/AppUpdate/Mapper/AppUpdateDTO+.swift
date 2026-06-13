//
//  AppUpdateDTO+.swift
//  Model
//
//  AppStoreInfoDTO → AppUpdateInfo 매핑 (버전 비교 포함).
//

import Foundation

import Entity

public extension AppStoreInfoDTO {
  func toEntity(currentVersion: String) -> AppUpdateInfo {
    AppUpdateInfo(
      currentVersion: currentVersion,
      latestVersion: version,
      releaseNotes: releaseNotes,
      appStoreUrl: trackViewUrl,
      isUpdateAvailable: isNewerVersion(storeVersion: version, currentVersion: currentVersion)
    )
  }

  private func isNewerVersion(storeVersion: String, currentVersion: String) -> Bool {
    storeVersion.compare(currentVersion, options: .numeric) == .orderedDescending
  }
}
