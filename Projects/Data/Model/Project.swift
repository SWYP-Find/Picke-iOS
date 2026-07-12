import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .module(name: "Model"),
  bundleId: .appBundleID(name: ".Model"),
  product: .staticFramework,
  settings: .settings(),
  dependencies: [
    .Domain(.Common, .interface),
    .Domain(.Comment, .interface),
    .Domain(.Home, .interface),
    .Domain(implements: .Entity),
  ],
  sources: ["Sources/**"],
  hasTests: false
)
