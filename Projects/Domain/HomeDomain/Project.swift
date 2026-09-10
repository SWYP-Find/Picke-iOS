import Foundation

import DependencyPackagePlugin
import DependencyPlugin
import ProjectTemplatePlugin

import ProjectDescription

let project = Project.makeModule(
  name: "HomeDomain",
  bundleId: .appBundleID(name: ".HomeDomain"),
  product: .framework,
  settings: .settings(),
  dependencies: [
    .serviceAssembly,
    .domain(.auth, .interface),
  ],
  hasTests: true,
  hasInterface: true,
  interfaceDependencies: [
    .SPM.composableArchitecture,
  ],
  hasTesting: true
)