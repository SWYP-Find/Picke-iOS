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
    .Domain(.Battle, .interface),
    .Domain(.Comment, .interface),
    .api,
    .Data(implements: .Model),
    .apiEndpoint,
    .Network(implements: .NetworkModule),
    .Network(implements: .NetworkHeader),
    .SPM.weaveDI,
    .SPM.logMarco,
    .SPM.composableArchitecture,
  ],
  sources: ["Sources/**"],
  hasTests: true
)
