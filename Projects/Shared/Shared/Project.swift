import Foundation
import ProjectDescription
import DependencyPlugin
import ProjectTemplatePlugin
import DependencyPackagePlugin

let project = Project.configure(
  moduleType: .module(name: "Shared"),
  bundleId: .appBundleID(name: ".Shared"),
  product: .framework,
  settings:  .settings(),
  dependencies: [
    .Shared(implements: .PickeDesignKit),
    .Shared(implements: .Utill),
    .Shared(implements: .ThirdParty)
  ],
  sources: ["Sources/**"],
  hasTests: false
)
