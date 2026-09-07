import Foundation

import DependencyPackagePlugin
import DependencyPlugin
import ProjectTemplatePlugin

import ProjectDescription

let project = Project.configure(
  moduleType: .microModule(name: "PickeStorage"),
  bundleId: .appBundleID(name: ".PickeStorage"),
  product: .framework,
  settings: .settings(),
  dependencies: [

  ],
  interfaceDependencies: [
    .SPM.composableArchitecture,
    .SPM.sharing,
    .SPM.sqliteData,
  ]
)
