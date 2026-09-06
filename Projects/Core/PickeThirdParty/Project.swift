import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .module(name: "PickeThirdParty"),
  bundleId: .appBundleID(name: ".PickeThirdParty"),
  product: .framework,
  settings: .settings(),
  dependencies: [
    .core(.coreUtility),
    .designSystem,
    .SPM.composableArchitecture,
    .SPM.tcaFlow,
    .SPM.sdwebImage,
  ],
  sources: ["Sources/**"],
  hasTests: false
)
