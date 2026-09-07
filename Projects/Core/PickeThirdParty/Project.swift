import Foundation

import DependencyPackagePlugin
import DependencyPlugin
import ProjectTemplatePlugin

import ProjectDescription

let project = Project.configure(
  moduleType: .module(name: "PickeThirdParty"),
  bundleId: .appBundleID(name: ".PickeThirdParty"),
  product: .framework,
  settings: .settings(),
  dependencies: [
    .core(.coreUtility),
    .SPM.composableArchitecture,
    .SPM.tcaFlow,
    .SPM.sdwebImage,
  ],
  sources: ["Sources/**"],
  hasTests: false
)
