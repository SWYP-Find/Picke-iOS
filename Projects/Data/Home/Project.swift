import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .module(name: "HomeData"),
  bundleId: .appBundleID(name: ".HomeData"),
  product: .staticFramework,
  settings: .settings(),
  dependencies: [
    .Domain(.Auth, .interface),
    .Domain(.Home, .interface),
    .Domain(.Common, .interface),
    .Data(implements: .API),
    .Data(implements: .Model),
    .Data(implements: .Remote),
    .Network(implements: .NetworkModule),
    .Network(implements: .NetworkHeader),
    .SPM.weaveDI,
    .SPM.logMarco,
  ],
  sources: ["Sources/**"],
  hasTests: true
)
