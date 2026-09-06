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
    .domain(.battle, .interface),
    .domain(.comment, .interface),
    .SPM.weaveDI,
    .SPM.composableArchitecture,
  ],
  interfaceDependencies: [
    .domain(.battle, .interface),
    .domain(.comment, .interface),
    .SPM.weaveDI,
    .SPM.composableArchitecture,
  ]
)
