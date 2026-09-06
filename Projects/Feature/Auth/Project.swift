import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .microModule(name: "Auth"),
  bundleId: .appBundleID(name: ".Auth"),
  product: .staticFramework,
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
