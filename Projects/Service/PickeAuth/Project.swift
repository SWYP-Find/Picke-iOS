import Foundation

import DependencyPackagePlugin
import DependencyPlugin
import ProjectTemplatePlugin

import ProjectDescription

let project = Project.makeModule(
  name: "PickeAuth",
  bundleId: .appBundleID(name: ".PickeAuth"),
  product: .framework,
  settings: .settings(),
  dependencies: [
    .service(.apiEndpoint),
    .core(.network),
    .core(.storage),
    .core(.storage, .interface),
    .core(.logger),
  ],
  hasTests: true,
  hasInterface: true,
  interfaceDependencies: [
    .core(.network, .interface),
    .SPM.composableArchitecture,
  ],
  hasTesting: true
)