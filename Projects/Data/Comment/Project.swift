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
    .Domain(.Common, .interface),
    .Data(implements: .API),
    .Data(implements: .Model),
    .Data(implements: .Remote),
    .Data(implements: .Repository),
    .Network(implements: .NetworkHeader),
    .SPM.logMarco,
  ],
  sources: ["Sources/**"],
  hasTests: true
)
