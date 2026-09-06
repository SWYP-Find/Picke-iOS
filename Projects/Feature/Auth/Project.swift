import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .feature(.auth),
  bundleId: .appBundleID(name: ".Auth"),
  settings: .settings(),
  dependencies: [
    .designSystem,
    .service(.analytics, .interface),
    .SPM.composableArchitecture,
    .SPM.tcaFlow,
    .domain(.auth, .interface),
    
    
    .core(.thirdParty),
  ]
)
