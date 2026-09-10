import Foundation

import DependencyPackagePlugin
import DependencyPlugin
import ProjectTemplatePlugin

import ProjectDescription

let project = Project.makeModule(
  name: "PickeThirdParty",
  bundleId: .appBundleID(name: ".PickeThirdParty"),
  product: .framework,
  settings: .settings(),
  dependencies: [
    .core(.coreUtility),
    .SPM.composableArchitecture,
    .SPM.tcaFlow,
    .SPM.sdwebImage,
  ],
  hasTests: false
)