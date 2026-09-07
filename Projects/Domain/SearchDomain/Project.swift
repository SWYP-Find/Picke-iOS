import Foundation

import DependencyPackagePlugin
import DependencyPlugin
import ProjectTemplatePlugin

import ProjectDescription

let project = Project.makeModule(
  name: "SearchDomain",
  bundleId: .appBundleID(name: ".SearchDomain"),
  product: .framework,
  settings: .settings(),
  dependencies: [
    .serviceAssembly,
    .domain(.home, .interface),
    .domain(.battle, .interface),
  ],
  hasTests: true,
  hasInterface: true,
  interfaceDependencies: [
    .domain(.home, .interface),
    .SPM.composableArchitecture,
  ],
  hasTesting: false
)