import Foundation

import DependencyPackagePlugin
import DependencyPlugin
import ProjectTemplatePlugin

import ProjectDescription

let project = Project.makeModule(
  name: "Auth",
  bundleId: .appBundleID(name: ".Auth"),
  product: .staticFramework,
  settings: .settings(),
  dependencies: [
    .core(.logger),
    .SPM.composableArchitecture,
    .ui(.designKit),
    .ui(.sharedUI),
    .service(.analytics, .interface),
    .domain(.auth, .interface),
  ],
  hasTests: true,
  hasInterface: true,
  hasTesting: false
)