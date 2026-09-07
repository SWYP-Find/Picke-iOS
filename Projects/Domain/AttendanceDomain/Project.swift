import Foundation

import DependencyPackagePlugin
import DependencyPlugin
import ProjectTemplatePlugin

import ProjectDescription

let project = Project.configure(
  moduleType: .microModule(name: "AttendanceDomain"),
  bundleId: .appBundleID(name: ".AttendanceDomain"),
  product: .framework,
  settings: .settings(),
  dependencies: [
    .serviceAssembly,
  ],
  interfaceDependencies: [.SPM.composableArchitecture]
)
