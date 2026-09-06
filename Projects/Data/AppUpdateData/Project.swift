import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .module(name: "AppUpdateData"),
  bundleId: .appBundleID(name: ".AppUpdateData"),
  product: .staticFramework,
  settings: .settings(),
  dependencies: [
    .domain(.appUpdate, .interface),
    .data(.model),
    .network(implements: .networkModule),
    .SPM.logMarco,
    .SPM.composableArchitecture,
  ],
  sources: ["Sources/**"],
  hasTests: false
)
