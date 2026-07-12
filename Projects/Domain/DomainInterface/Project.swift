import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .module(name: "DomainInterface"),
  bundleId: .appBundleID(name: ".DomainInterface"),
  product: .staticFramework,
  settings: .settings(),
  dependencies: [
    .Domain(.Common, .interface),
    .Domain(.Comment, .interface),
    .Domain(.Home, .interface),
    .Domain(implements: .Entity),
    .SPM.weaveDI,
    .SPM.composableArchitecture,
  ],
  sources: ["Sources/**"],
  hasTests: false
)
