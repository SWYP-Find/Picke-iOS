import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .module(name: "PickeFoundation"),
  bundleId: .appBundleID(name: ".PickeFoundation"),
  product: .staticFramework,
  settings: .settings(),
  dependencies: [
  ],
  sources: ["Sources/**"],
  hasTests: false
)
