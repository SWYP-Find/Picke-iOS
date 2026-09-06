import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .module(name: "ProfileData"),
  bundleId: .appBundleID(name: ".ProfileData"),
  product: .staticFramework,
  settings: .settings(),
  dependencies: [
    .domain(.profile, .interface),
    .api,
    .data(implements: .model),
    .apiEndpoint,
    .network(implements: .networkModule),
    .network(implements: .networkHeader),
    .SPM.logMarco,
    .SPM.composableArchitecture,
  ],
  sources: ["Sources/**"],
  hasTests: true
)
