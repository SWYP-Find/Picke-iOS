import Foundation

import DependencyPackagePlugin
import DependencyPlugin
import ProjectTemplatePlugin

import ProjectDescription

let project = Project.makeModule(
  name: "DeviceService",
  bundleId: .appBundleID(name: ".DeviceService"),
  product: .framework,
  settings: .settings(),
  dependencies: [
    .service(.apiEndpoint),
    .core(.network),
    .SPM.composableArchitecture,
    .core(.logger),
  ],
  hasTests: true,
  hasInterface: true,
  interfaceDependencies: [
    .SPM.composableArchitecture,
  ],
  hasTesting: false
)