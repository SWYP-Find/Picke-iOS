import Foundation

import DependencyPackagePlugin
import DependencyPlugin
import ProjectTemplatePlugin

import ProjectDescription

let project = Project.configure(
  moduleType: .microModule(name: "Chat"),
  bundleId: .appBundleID(name: ".Chat"),
  product: .staticFramework,
  settings: .settings(),
  dependencies: [
    .SPM.tcaFlow,
    .SPM.composableArchitecture,
    .service(.audioPlayer, .interface),
    .domain(.perspective, .interface),
    .ui(.designKit),
    .ui(.sharedUI),
    .core(.coreUtility),
    .service(.analytics, .interface),
    .domain(.battle, .interface),
    .domain(.home, .interface),
    .core(.network),

    .domain(.comment, .interface),
    .feature(.ad, .implementation),
  ]
)
