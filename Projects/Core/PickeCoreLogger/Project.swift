import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .module(name: "PickeCoreLogger"),
  bundleId: .appBundleID(name: ".PickeCoreLogger"),
  product: .staticFramework,
  settings: .settings(),
  dependencies: [
  ],
  sources: ["Sources/**"],
  hasTests: true
)
