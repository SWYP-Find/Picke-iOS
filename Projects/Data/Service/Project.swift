import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .module(name: "Service"),
  bundleId: .appBundleID(name: ".Service"),
  product: .staticFramework,
  settings: .settings(),
  dependencies: [
    .Data(implements: .API),
    .Domain(implements: .Entity),
    .Network(implements: .NetworkHeader),
  ],
  sources: ["Sources/**"],
  hasTests: false
)
