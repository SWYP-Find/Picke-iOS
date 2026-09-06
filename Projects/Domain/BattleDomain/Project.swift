import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .microModule(name: "BattleDomain"),
  bundleId: .appBundleID(name: ".BattleDomain"),
  settings: .settings(),
  dependencies: [
    .SPM.weaveDI,
    .SPM.composableArchitecture,
    .domain(.home, .interface),
    .service(.api),
    .data(.model),
    .service(.apiEndpoint),
    .core(.network),
    .core(.network, .interface),
    .SPM.logMarco,
  ],
  interfaceDependencies: [
    .domain(.home, .interface),
    
    .SPM.weaveDI,
    .SPM.composableArchitecture,
  ]
)
