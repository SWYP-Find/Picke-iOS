//
//  AppUpdateInfo.swift
//  Entity
//

import Foundation

public struct AppUpdateInfo: Codable, Equatable, Sendable {
  public let currentVersion: String
  public let latestVersion: String
  public let releaseNotes: String?
  public let appStoreUrl: String
  public let isUpdateAvailable: Bool

  public init(
    currentVersion: String,
    latestVersion: String,
    releaseNotes: String?,
    appStoreUrl: String,
    isUpdateAvailable: Bool
  ) {
    self.currentVersion = currentVersion
    self.latestVersion = latestVersion
    self.releaseNotes = releaseNotes
    self.appStoreUrl = appStoreUrl
    self.isUpdateAvailable = isUpdateAvailable
  }
}
