import Foundation
import ProjectDescription
import DependencyPlugin
import ProjectTemplatePlugin
import DependencyPackagePlugin

let project = Project.configure(
  moduleType: .module(name: "ThirdPartys"),
  bundleId: .appBundleID(name: ".ThirdPartys"),
  product: .staticFramework,
  settings:  .settings(),
  dependencies: [
    .SPM.asyncMoya,
    .SPM.weaveDI
  ],
  sources: ["Sources/**"],
  hasTests: false
)
