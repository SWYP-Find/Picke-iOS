import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .module(name: "PickeCoreUtility"),
  bundleId: .appBundleID(name: ".PickeCoreUtility"),
  product: .staticFramework,
  settings: .settings(),
  dependencies: [
  ],
  sources: ["Sources/**"],
  hasTests: false
)
