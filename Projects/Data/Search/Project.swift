import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .module(name: "SearchData"),
  bundleId: .appBundleID(name: ".SearchData"),
  product: .staticFramework,
  settings: .settings(),
  dependencies: [
    .Domain(.Search, .interface),
    .Domain(implements: .Entity),
    .Data(implements: .API),
    .Data(implements: .Model),
    .Data(implements: .Repository),
    .Network(implements: .NetworkHeader),
    .SPM.asyncMoya,
    .SPM.logMarco,
  ],
  sources: ["Sources/**"],
  hasTests: false
)
