import Foundation

import DependencyPackagePlugin
import DependencyPlugin
import ProjectTemplatePlugin

import ProjectDescription

let project = Project.configure(
  moduleType: .microModule(name: "PickeAuth"),
  bundleId: .appBundleID(name: ".PickeAuth"),
  product: .framework,
  settings: .settings(),
  dependencies: [
    .service(.apiEndpoint),
    .core(.network),
    .core(.storage),
    .core(.storage, .interface),
    .SPM.composableArchitecture,
    .SPM.logMarco,
  ],
  interfaceDependencies: [
    .core(.network, .interface),
    .SPM.composableArchitecture,
  ]
)
