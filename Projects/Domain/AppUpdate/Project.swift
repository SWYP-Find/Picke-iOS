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
  ],
  interfaceDependencies: [
    .SPM.weaveDI,
    .SPM.composableArchitecture,
  ]
)
