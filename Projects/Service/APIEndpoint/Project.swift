import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .module(name: "APIEndpoint"),
  bundleId: .appBundleID(name: ".APIEndpoint"),
  product: .staticFramework,
  settings: .settings(),
  dependencies: [
    .api,
    .Network(implements: .NetworkHeader),
  ],
  sources: ["Sources/**"],
  hasTests: false
)
