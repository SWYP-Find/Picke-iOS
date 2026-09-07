import Foundation

import DependencyPackagePlugin
import DependencyPlugin
import ProjectTemplatePlugin

import ProjectDescription

let project = Project.configure(
  moduleType: .microModule(name: "AppUpdateDomain"),
  bundleId: .appBundleID(name: ".AppUpdateDomain"),
  product: .framework,
  settings: .settings(),
  dependencies: [
    .serviceAssembly,
  ],
  interfaceDependencies: [
    .SPM.composableArchitecture,
  ]
)
