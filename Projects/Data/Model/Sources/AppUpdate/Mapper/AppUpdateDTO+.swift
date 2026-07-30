//
//  AppUpdateDTO+.swift
//  Model
//

import Foundation
import AppUpdateDomainInterface


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
