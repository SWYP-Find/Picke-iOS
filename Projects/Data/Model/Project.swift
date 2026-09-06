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
    .domain(.appUpdate, .interface),
    .domain(.comment, .interface),
    .domain(.battle, .interface),
    .domain(.home, .interface),
  ],
  sources: ["Sources/**"],
  hasTests: false
)
