import Foundation

import DependencyPackagePlugin
import DependencyPlugin
import ProjectTemplatePlugin

import ProjectDescription

let project = Project.configure(
  moduleType: .microModule(name: "BattleDomain"),
  bundleId: .appBundleID(name: ".BattleDomain"),
  product: .framework,
  settings: .settings(),
  dependencies: [
    .serviceAssembly,
    .SPM.composableArchitecture,
    .domain(.home, .interface),
  ],
  interfaceDependencies: [
    .domain(.home, .interface),
    .SPM.composableArchitecture,
  ]
)
