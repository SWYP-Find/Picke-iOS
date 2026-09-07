import Foundation

import DependencyPackagePlugin
import DependencyPlugin
import ProjectTemplatePlugin

import ProjectDescription

let project = Project.makeModule(
  name: "AudioPlayerService",
  bundleId: .appBundleID(name: ".AudioPlayerService"),
  product: .framework,
  settings: .settings(),
  dependencies: [
    
  ],
  hasTests: true,
  hasInterface: true,
  interfaceDependencies: [
    .SPM.composableArchitecture,
  ],
  hasTesting: false
)