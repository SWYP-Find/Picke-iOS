import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .microModule(name: "AppUpdateDomain"),
  bundleId: .appBundleID(name: ".AppUpdateDomain"),
  product: .framework,
  settings: .settings(),
  dependencies: [
    .SPM.composableArchitecture,
    .core(.network),
    .SPM.logMarco,
  ],
  interfaceDependencies: [
    .SPM.composableArchitecture,
  ]
)
