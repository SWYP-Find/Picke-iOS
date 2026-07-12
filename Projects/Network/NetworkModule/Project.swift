import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .module(name: "NetworkModule"),
  bundleId: .appBundleID(name: ".NetworkModule"),
  product: .staticFramework,
  settings: .settings(),
  dependencies: [
    .Network(implements: .NetworkToken),
    .Network(implements: .NetworkHeader),
    .Network(implements: .Networking),
    .Network(implements: .ThirdPartys),
  ],
  sources: ["Sources/**"]
)
