import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .module(name: "DomainTesting"),
  bundleId: .appBundleID(name: ".DomainTesting"),
  product: .framework,
  settings: .settings(),
  dependencies: [
    .Domain(implements: .UseCase),
  ],
  sources: ["Sources/**"]
)
