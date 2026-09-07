import Foundation

import DependencyPackagePlugin
import DependencyPlugin
import ProjectTemplatePlugin

import ProjectDescription

let project = Project.configure(
  moduleType: .microModule(name: "Auth"),
  bundleId: .appBundleID(name: ".Auth"),
  product: .staticFramework,
  settings: .settings(),
  dependencies: [
    .SPM.composableArchitecture,
    .ui(.designKit),
    .ui(.sharedUI),
    .service(.analytics, .interface),
    .domain(.auth, .interface),
  ]
)
