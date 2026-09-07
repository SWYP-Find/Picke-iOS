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
    .ui(.designKit),
    .ui(.sharedUI),
    .service(.analytics, .interface),
    .SPM.composableArchitecture,
    .SPM.tcaFlow,
    .domain(.auth, .interface),
    
    
    .core(.thirdParty),
  ]
)
