import Foundation

import DependencyPackagePlugin
import DependencyPlugin
import ProjectTemplatePlugin

import ProjectDescription

let project = Project.makeModule(
  name: "BattleDomain",
  bundleId: .appBundleID(name: ".BattleDomain"),
  product: .framework,
  settings: .settings(),
  dependencies: [
    .serviceAssembly,
    .SPM.composableArchitecture,
    .domain(.home, .interface),
  ],
  hasTests: true,
  hasInterface: true,
  interfaceDependencies: [
    .domain(.home, .interface),
    .SPM.composableArchitecture,
  ],
  hasTesting: false
)