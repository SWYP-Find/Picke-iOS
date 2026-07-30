import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .module(name: "Remote"),
  bundleId: .appBundleID(name: ".Remote"),
  product: .staticFramework,
  settings: .settings(),
  dependencies: [
    .Data(implements: .API),
    
    .Network(implements: .NetworkHeader),
  ],
  sources: ["Sources/**"],
  hasTests: false
)
