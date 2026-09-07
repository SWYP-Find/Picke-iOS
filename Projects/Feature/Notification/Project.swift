import Foundation

import DependencyPackagePlugin
import DependencyPlugin
import ProjectTemplatePlugin

import ProjectDescription

let project = Project.configure(
  moduleType: .microModule(name: "Notification"),
  bundleId: .appBundleID(name: ".Notification"),
  product: .staticFramework,
  settings: .settings(),
  dependencies: [
    .ui(.designKit),
    .ui(.sharedUI),
    .core(.coreUtility),
    .service(.analytics, .interface),
    .domain(.notification, .interface),
    .SPM.composableArchitecture,
    .SPM.tcaFlow,
  ]
)
