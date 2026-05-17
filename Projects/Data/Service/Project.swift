import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.makeModule(
  name: "Service",
  bundleId: .appBundleID(name: ".Service"),
  product: .staticFramework,
  settings: .settings(),
  dependencies: [
    .Data(implements: .API),
    .Domain(implements: .Entity),
    .Network(implements: .Foundations),
    .SPM.asyncMoya,
  ],
  sources: ["Sources/**"],
  hasTests: false
)
