import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .module(name: "NetworkHeader"),
  bundleId: .appBundleID(name: ".NetworkHeader"),
  product: .staticFramework,
  settings: .settings(),
  dependencies: [
    .Network(implements: .NetworkToken),
    .SPM.alamofire,
  ],
  sources: ["Sources/**"],
  hasTests: false
)
