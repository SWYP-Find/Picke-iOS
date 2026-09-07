import Foundation

import DependencyPackagePlugin
import DependencyPlugin
import ProjectTemplatePlugin

import ProjectDescription

let project = Project.configure(
  moduleType: .microModule(name: "Web"),
  bundleId: .appBundleID(name: ".Web"),
  product: .staticFramework,
  settings: .settings(),
  dependencies: [
    .ui(.designKit),
    .SPM.composableArchitecture,
  ]
)
