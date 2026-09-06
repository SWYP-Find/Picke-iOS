import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .module(name: "CommentData"),
  bundleId: .appBundleID(name: ".CommentData"),
  product: .staticFramework,
  settings: .settings(),
  dependencies: [
    .domain(.comment, .interface),
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
