import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.makeModule(
  name: "Domain",
  bundleId: .appBundleID(name: ".Domain"),
  product: .staticFramework,
  settings: .settings(),
  dependencies: [
    .Domain(implements: .Entity),
    .Domain(implements: .DomainInterface),
    .Domain(implements: .UseCase),
  ],
  sources: ["Sources/**"]
)
