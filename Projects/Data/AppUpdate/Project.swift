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
    .Domain(.AppUpdate, .interface),
    .Data(implements: .Model),
    .Network(implements: .NetworkModule),
    .SPM.logMarco,
  ],
  sources: ["Sources/**"],
  hasTests: false
)
