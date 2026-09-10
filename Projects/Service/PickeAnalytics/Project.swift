import Foundation

import DependencyPackagePlugin
import DependencyPlugin
import ProjectTemplatePlugin

import ProjectDescription

let project = Project.makeModule(
  name: "PickeAnalytics",
  bundleId: .appBundleID(name: ".PickeAnalytics"),
  product: .framework,
  settings: .settings(),
  dependencies: [
    .core(.logger),
    .core(.network),
    .SPM.mixpanel,
    .SPM.mixpanelSessionReplay,
    .SPM.sentry,
    .SPM.sentrySwiftUI,
  ],
  hasTests: true,
  hasInterface: true,
  interfaceDependencies: [
    .SPM.composableArchitecture,
  ],
  hasTesting: false
)