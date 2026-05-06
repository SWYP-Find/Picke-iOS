import Foundation
import ProjectDescription
import DependencyPlugin
import ProjectTemplatePlugin
import DependencyPackagePlugin

let project = Project.makeModule(
  name: "UseCase",
  bundleId: .appBundleID(name: ".UseCase"),
  product: .staticFramework,
  settings:  .settings(),
  dependencies: [
    .Domain(implements: .DomainInterface),
    .SPM.composableArchitecture,
    .SPM.weaveDI,
  ],
  sources: ["Sources/**"],
  hasTests: true
)
