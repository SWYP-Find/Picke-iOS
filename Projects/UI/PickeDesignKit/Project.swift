import Foundation

import DependencyPackagePlugin
import DependencyPlugin
import ProjectTemplatePlugin

import ProjectDescription

let project = Project.makeModule(
  name: "PickeDesignKit",
  bundleId: .appBundleID(name: ".PickeDesignKit"),
  product: .framework,
  settings: .settings(),
  dependencies: [
    .core(.coreUI),
    .SPM.composableArchitecture,
  ],
  resources: ["Resources/**"],
  hasTests: true,
  hasDemo: true,
  demoDisplayName: "Picke 스토리북"
)