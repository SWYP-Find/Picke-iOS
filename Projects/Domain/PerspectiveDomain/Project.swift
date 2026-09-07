import Foundation

import DependencyPackagePlugin
import DependencyPlugin
import ProjectTemplatePlugin

import ProjectDescription

let project = Project.makeModule(
  name: "PerspectiveDomain",
  bundleId: .appBundleID(name: ".PerspectiveDomain"),
  product: .framework,
  settings: .settings(),
  dependencies: [
    .serviceAssembly,
    .domain(.battle, .interface),
    .domain(.comment, .interface),
  ],
  hasTests: true,
  hasInterface: true,
  interfaceDependencies: [
    .domain(.battle, .interface),
    .domain(.comment, .interface),
    .SPM.composableArchitecture,
  ],
  hasTesting: false
)