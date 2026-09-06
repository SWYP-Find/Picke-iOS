import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .microModule(name: "PerspectiveDomain"),
  bundleId: .appBundleID(name: ".PerspectiveDomain"),
  settings: .settings(),
  dependencies: [
    .Domain(.Battle, .interface),
    .Domain(.Comment, .interface),
    .SPM.weaveDI,
    .SPM.composableArchitecture,
  ],
  interfaceDependencies: [
    .Domain(.Battle, .interface),
    .Domain(.Comment, .interface),
    .SPM.weaveDI,
    .SPM.composableArchitecture,
  ]
)
