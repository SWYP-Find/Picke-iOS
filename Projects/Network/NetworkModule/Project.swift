import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.makeModule(
  name: "NetworkModule",
  bundleId: .appBundleID(name: ".NetworkModule"),
  product: .staticFramework,
  settings: .settings(),
  dependencies: [
    .Network(implements: .Foundations),
    .Network(implements: .Networking),
    .Network(implements: .ThirdPartys),
  ],
  sources: ["Sources/**"]
)
