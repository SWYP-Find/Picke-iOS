import Foundation

import DependencyPackagePlugin
import DependencyPlugin
import ProjectTemplatePlugin

import ProjectDescription

let project = Project.makeModule(
  name: "PickeCoreUtility",
  bundleId: .appBundleID(name: ".PickeCoreUtility"),
  product: .framework,
  settings: .settings(),
  dependencies: [
  ],
  hasTests: true
)