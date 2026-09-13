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
    .domain(.ad, .interface),
    .ui(.designKit),
    .ui(.sharedUI),
    .feature(.featureSharedUI, .implementation),
    .SPM.composableArchitecture,
    .SPM.adFit,
    .SPM.googleMobileAds,
    .service(.analytics, .interface),
  ],
  hasTests: false,
  hasInterface: true,
  interfaceDependencies: [
    .SPM.composableArchitecture,
  ],
  hasTesting: false
)
