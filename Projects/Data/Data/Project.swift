import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .module(name: "Data"),
  bundleId: .appBundleID(name: ".Data"),
  product: .staticFramework,
  settings: .settings(),
  dependencies: [
    .Data(implements: .API),
    .Data(implements: .Model),
    .Data(implements: .Service),
    .Data(implements: .Repository),
    .Data(.Profile),
  ],
  sources: ["Sources/**"]
)
