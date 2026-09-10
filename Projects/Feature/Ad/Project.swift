import Foundation

import DependencyPackagePlugin
import DependencyPlugin
import ProjectTemplatePlugin

import ProjectDescription

let project = Project.makeModule(
  name: "Ad",
  bundleId: .appBundleID(name: ".Ad"),
  settings: .settings(),
  dependencies: [
    .core(.logger),
    .SPM.adFit,
    .SPM.googleMobileAds,
    .service(.analytics, .interface),
  ],
  hasTests: true,
  hasInterface: true,
  interfaceDependencies: [
    .SPM.composableArchitecture,
  ],
  hasTesting: false
)