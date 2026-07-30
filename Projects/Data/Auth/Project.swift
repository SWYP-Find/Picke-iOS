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
    
    .Data(implements: .API),
    .Data(implements: .Model),
    .Data(implements: .Remote),
    .Data(implements: .Repository),
    .Network(implements: .NetworkHeader),
    .SPM.weaveDI,
    .SPM.logMarco,
    .SPM.composableArchitecture,
    .SPM.googleSignIn,
  ],
  sources: ["Sources/**"],
  hasTests: true
)
