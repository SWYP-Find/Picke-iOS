import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .microModule(name: "BattleDomain"),
  bundleId: .appBundleID(name: ".BattleDomain"),
  product: .framework,
  settings: .settings(),
  dependencies: [
    .SPM.composableArchitecture,
    .domain(.home, .interface),
    .service(.api),
    .service(.apiEndpoint),
    .core(.coreUtility),
    .core(.network),
    .core(.network, .interface),
    .SPM.logMarco,
  ],
  interfaceDependencies: [
    .domain(.home, .interface),
    
    .SPM.composableArchitecture,
  ]
)
