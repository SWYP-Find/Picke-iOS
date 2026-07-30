import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .microModule(name: "SearchDomain"),
  bundleId: .appBundleID(name: ".SearchDomain"),
  product: .staticFramework,
  settings: .settings(),
  dependencies: [
    .Domain(.Home, .interface),
    
    .SPM.weaveDI,
    .SPM.composableArchitecture,
  ],
  interfaceDependencies: [
    .Domain(.Home, .interface),
    
    .SPM.weaveDI,
    .SPM.composableArchitecture,
  ]
)
