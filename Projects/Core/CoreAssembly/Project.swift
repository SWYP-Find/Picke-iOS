import Foundation

import DependencyPackagePlugin
import DependencyPlugin
import ProjectTemplatePlugin

import ProjectDescription

let project = Project.makeModule(
  name: "CoreAssembly",
  bundleId: .appBundleID(name: ".CoreAssembly"),
  product: .staticFramework,
  settings: .settings(),
  dependencies: [
    .core(.thirdParty),
    .core(.logger),
    .core(.network),
    .core(.coreUtility),
    .core(.coreUI),
    .core(.storage, .implementation),
    .SPM.composableArchitecture,
  ],
  hasTests: true
)