import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .microModule(name: "AppUpdateDomain"),
  bundleId: .appBundleID(name: ".AppUpdateDomain"),
  product: .staticFramework,
  settings: .settings(),
  dependencies: [
    .SPM.composableArchitecture,
    .data(.model),
    .network(implements: .networkModule),
    .SPM.logMarco,
  ],
  interfaceDependencies: [
    .SPM.weaveDI,
    .SPM.composableArchitecture,
  ]
)
