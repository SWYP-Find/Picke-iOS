import Foundation

import DependencyPackagePlugin
import DependencyPlugin
import ProjectTemplatePlugin

import ProjectDescription

let project = Project.makeModule(
  name: "ProfileDomain",
  bundleId: .appBundleID(name: ".ProfileDomain"),
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