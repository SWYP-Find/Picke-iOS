//
//  Extension+String.swift
//  MyPlugin
//
//  Created by 서원지 on 1/6/24.
//

import Foundation
import ProjectDescription

public extension String {
  static func appVersion(version: String = "1.0.7") -> String {
    return version
  }

  static func mainBundleID() -> String {
    return Project.Environment.bundlePrefix
  }

  static func appBuildVersion(buildVersion: String = "2607300031") -> String {
    return buildVersion
  }

  static func appBundleID(name: String) -> String {
    return Project.Environment.bundlePrefix + name
  }
}
