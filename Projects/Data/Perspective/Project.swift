import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .module(name: "PerspectiveData"),
  bundleId: .appBundleID(name: ".PerspectiveData"),
  product: .staticFramework,
  settings: .settings(),
  dependencies: [
    .Domain(.Perspective, .interface),
    .Domain(.Common, .interface),
    .Domain(.Comment, .interface),
    .Data(implements: .API),
    .Data(implements: .Model),
    .Data(implements: .Service),
    .Data(implements: .Repository),
    .Network(implements: .NetworkHeader),
    .SPM.asyncMoya,
    .SPM.weaveDI,
    .SPM.logMarco,
  ],
  sources: ["Sources/**"],
  hasTests: false
)
