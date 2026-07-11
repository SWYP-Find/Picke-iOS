import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .module(name: "DesignSystem"),
  bundleId: .appBundleID(name: ".DesignSystem"),
  product: .staticFramework,
  settings: .settings(),
  dependencies: [
    .SPM.composableArchitecture,
    .Shared(implements: .ThirdParty),
  ],
  sources: ["Sources/**"],
  resources: ["Resources/**"],
  hasTests: false
)
