import Foundation

import DependencyPackagePlugin
import DependencyPlugin
import ProjectTemplatePlugin

import ProjectDescription

let project = Project.makeModule(
  name: "PickeStorage",
  bundleId: .appBundleID(name: ".PickeStorage"),
  product: .framework,
  settings: .settings(),
  dependencies: [

  ],
  hasTests: true,
  hasInterface: true,
  interfaceDependencies: [
    .SPM.composableArchitecture,
    .SPM.sharing,
    .SPM.sqliteData,
  ],
  hasTesting: false
)