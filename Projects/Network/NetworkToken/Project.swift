import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .module(name: "NetworkToken"),
  bundleId: .appBundleID(name: ".NetworkToken"),
  product: .staticFramework,
  settings: .settings(),
  dependencies: [
    .SPM.weaveDI,
    .SPM.dependencies,
  ],
  sources: ["Sources/**"],
  hasTests: false
)
