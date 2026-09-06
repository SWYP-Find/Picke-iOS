import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .microModule(name: "Battle"),
  bundleId: .appBundleID(name: ".Battle"),
  product: .staticFramework,
  settings: .settings(),
  dependencies: [
    .ui(.designKit),
    .core(.coreUtility),
    .service(.analytics, .interface),
    .core(.thirdParty),
    .domain(.battle, .interface),
    
    .SPM.composableArchitecture,
    .SPM.tcaFlow,
    .SPM.kingfisher,
  ]
)
