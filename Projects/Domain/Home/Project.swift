import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .microModule(name: "HomeDomain"),
  bundleId: .appBundleID(name: ".HomeDomain"),
  settings: .settings(),
  dependencies: [
    .Domain(.Common, .interface),
    .Domain(.Notification),
    .SPM.weaveDI,
    .SPM.composableArchitecture,
  ],
  interfaceDependencies: [
    .Domain(.Common, .interface),
    .SPM.weaveDI,
    .SPM.composableArchitecture,
  ]
)
