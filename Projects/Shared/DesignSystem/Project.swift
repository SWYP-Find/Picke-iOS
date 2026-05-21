import Foundation
import ProjectDescription
import DependencyPlugin
import ProjectTemplatePlugin
import DependencyPackagePlugin

let project = Project.makeModule(
  name: "DesignSystem",
  bundleId: .appBundleID(name: ".DesignSystem"),
  product: .staticFramework,
  settings:  .settings(),
  dependencies: [
    .SPM.composableArchitecture,
    .Shared(implements: .ThirdParty)
  ],
  sources: ["Sources/**"],
  resources: ["Resources/**", "FontAsset/**"],
  hasTests: false
)
