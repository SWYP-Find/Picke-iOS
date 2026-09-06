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
    .domain(.auth, .interface),
    
    .api,
    .data(implements: .model),
    .apiEndpoint,
    .network(implements: .networkModule),
    .network(implements: .networkHeader),
    .SPM.weaveDI,
    .SPM.logMarco,
    .SPM.composableArchitecture,
    .SPM.googleSignIn,
  ],
  sources: ["Sources/**"],
  hasTests: true
)
