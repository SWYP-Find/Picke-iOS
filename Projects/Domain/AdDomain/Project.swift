import Foundation

import DependencyPackagePlugin
import DependencyPlugin
import ProjectTemplatePlugin

import ProjectDescription

let project = Project.makeModule(
  name: "AdDomain",
  bundleId: .appBundleID(name: ".AdDomain"),
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
