import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .module(name: "API"),
  bundleId: .appBundleID(name: ".API"),
  product: .staticFramework,
  settings: .settings(),
  dependencies: [
    .network(implements: .networkHeader),
  ],
  sources: ["Sources/**"],
  hasTests: false
)
