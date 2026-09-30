import Foundation

import DependencyPackagePlugin
import DependencyPlugin
import ProjectTemplatePlugin

import ProjectDescription

let project = Project.makeModule(
  name: "Class",
  bundleId: .appBundleID(name: ".Class"),
  product: .staticFramework,
  settings: .settings(),
  dependencies: [
    .ui(.designKit),
    .ui(.sharedUI),
    .domain(.classroom, .interface),
    .SPM.composableArchitecture,
  ],
  hasTests: true,
  hasInterface: true,
  interfaceDependencies: [
    .domain(.classroom, .interface),
  ],
  hasTesting: false
)
