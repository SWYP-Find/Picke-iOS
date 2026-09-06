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
    
    .api,
    .Data(implements: .Model),
    .Data(implements: .Remote),
    .Network(implements: .NetworkModule),
    .Network(implements: .NetworkHeader),
    .SPM.weaveDI,
    .SPM.logMarco,
    .SPM.composableArchitecture,
    .SPM.googleSignIn,
  ],
  sources: ["Sources/**"],
  hasTests: true
)
