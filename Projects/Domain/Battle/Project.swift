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
    .Domain(.Common, .interface),
    
    .SPM.weaveDI,
    .SPM.composableArchitecture,
  ],
  interfaceDependencies: [
    .Domain(.Home, .interface),
    .Domain(.Common, .interface),
    
    .SPM.weaveDI,
    .SPM.composableArchitecture,
  ]
)
