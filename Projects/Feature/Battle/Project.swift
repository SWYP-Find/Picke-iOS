import Foundation

import DependencyPackagePlugin
import DependencyPlugin
import ProjectTemplatePlugin

import ProjectDescription

let project = Project.makeModule(
  name: "Battle",
  bundleId: .appBundleID(name: ".Battle"),
  product: .staticFramework,
  settings: .settings(),
  dependencies: [
    .core(.logger),
    .SPM.composableArchitecture,
    .ui(.designKit),
    .ui(.sharedUI),
    .core(.coreUtility),
    .service(.analytics, .interface),
    .domain(.battle, .interface),
  ],
  hasTests: true,
  hasInterface: true,
  hasTesting: false
)