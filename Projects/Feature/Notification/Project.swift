import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .microModule(name: "Notification"),
  bundleId: .appBundleID(name: ".Notification"),
  settings: .settings(),
  dependencies: [
    .designSystem,
    .core(.coreUtility),
    .service(.analytics, .interface),
    .domain(.notification, .interface),
    
    .core(.thirdParty),
    .SPM.composableArchitecture,
    .SPM.tcaFlow,
  ]
)
