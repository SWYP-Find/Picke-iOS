import Foundation

import DependencyPackagePlugin
import DependencyPlugin
import ProjectTemplatePlugin

import ProjectDescription

let project = Project.makeModule(
  name: "AppUpdateDomain",
  bundleId: .appBundleID(name: ".AppUpdateDomain"),
  product: .framework,
  settings: .settings(),
  dependencies: [
    .serviceAssembly,
  ],
  hasTests: true,
  hasInterface: true,
  interfaceDependencies: [
    .SPM.composableArchitecture,
  ],
  hasTesting: false
)