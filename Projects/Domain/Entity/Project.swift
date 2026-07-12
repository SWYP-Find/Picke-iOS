import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .module(name: "Entity"),
  bundleId: .appBundleID(name: ".Entity"),
  product: .staticFramework,
  settings: .settings(),
  dependencies: [
    .Domain(.Common, .interface),
    .Domain(.Profile, .interface),
  ],
  sources: ["Sources/**"],
  hasTests: false
)
