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
    .Domain(.AppUpdate, .interface),
    .Domain(.Comment, .interface),
    .Domain(.Battle, .interface),
    .Domain(.Home, .interface),
  ],
  sources: ["Sources/**"],
  hasTests: false
)
