import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .microModule(name: "Notification"),
  bundleId: .appBundleID(name: ".Notification"),
  product: .staticFramework,
  settings: .settings(),
  dependencies: [
    .ui(.designKit),
    .ui(.sharedUI),
    .core(.coreUtility),
    .service(.analytics, .interface),
    .domain(.notification, .interface),
    
    .core(.thirdParty),
    .SPM.composableArchitecture,
    .SPM.tcaFlow,
  ]
)
