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
  ],
  interfaceDependencies: [
    .Domain(.Home, .interface),
    
    .SPM.weaveDI,
    .SPM.composableArchitecture,
  ]
)
