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
    // Sources 가 ComposableArchitecture(DependencyKey)를 직접 import 한다.
    .SPM.composableArchitecture,
    .SPM.sqliteData,
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