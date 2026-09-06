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
    .domain(.perspective, .interface),
    .domain(.battle, .interface),
    .domain(.comment, .interface),
    .api,
    .model,
    .apiEndpoint,
    .network(implements: .networkModule),
    .network(implements: .networkHeader),
    .SPM.weaveDI,
    .SPM.logMarco,
    .SPM.composableArchitecture,
  ],
  sources: ["Sources/**"],
  hasTests: true
)
