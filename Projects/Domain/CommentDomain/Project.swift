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
    .domain(.battle, .interface),
    .SPM.weaveDI,
    .SPM.composableArchitecture,
  ],
  interfaceDependencies: [
    .domain(.battle, .interface),
    .SPM.weaveDI,
    .SPM.composableArchitecture,
  ]
)
