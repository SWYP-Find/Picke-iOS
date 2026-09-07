import Foundation

import DependencyPackagePlugin
import DependencyPlugin
import ProjectTemplatePlugin

import ProjectDescription

let project = Project.makeModule(
  name: "Splash",
  bundleId: .appBundleID(name: ".Splash"),
  product: .staticFramework,
  settings: .settings(),
  dependencies: [
    .ui(.designKit),
    .ui(.animation),
    .domain(.appUpdate, .interface),
    .service(.auth, .interface),
    .service(.analytics, .interface),
    .SPM.composableArchitecture,
  ],
  hasTests: true,
  hasInterface: true,
  hasTesting: false
)