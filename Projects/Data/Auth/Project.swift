import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .module(name: "AuthData"),
  bundleId: .appBundleID(name: ".AuthData"),
  product: .staticFramework,
  settings: .settings(),
  dependencies: [
    .Domain(.Auth, .interface),
    .Domain(implements: .Entity),
    .Data(implements: .API),
    .Data(implements: .Model),
    .Data(implements: .Service),
    .Data(implements: .Repository),
    .Network(implements: .NetworkHeader),
    .SPM.asyncMoya,
    .SPM.weaveDI,
    .SPM.logMarco,
    .SPM.composableArchitecture,
    .SPM.googleSignIn,
  ],
  sources: ["Sources/**"],
  hasTests: false
)
