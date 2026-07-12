import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .microModule(name: "CommentDomain"),
  bundleId: .appBundleID(name: ".CommentDomain"),
  settings: .settings(),
  dependencies: [
    .Domain(.Common, .interface),
    .SPM.weaveDI,
    .SPM.composableArchitecture,
  ],
  interfaceDependencies: [
    .Domain(.Common, .interface),
    .SPM.weaveDI,
    .SPM.composableArchitecture,
  ]
)
