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
    .Domain(.Comment, .interface),
    .api,
    .Data(implements: .Model),
    .apiEndpoint,
    .Network(implements: .NetworkModule),
    .Network(implements: .NetworkHeader),
    .SPM.logMarco,
    .SPM.composableArchitecture,
  ],
  sources: ["Sources/**"],
  hasTests: true
)
