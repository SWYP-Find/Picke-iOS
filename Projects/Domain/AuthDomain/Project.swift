import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .microModule(name: "AuthDomain"),
  bundleId: .appBundleID(name: ".AuthDomain"),
  product: .staticFramework,
  settings: .settings(),
  dependencies: [
    .core(.storage, .interface),
    .SPM.composableArchitecture,
    .SPM.weaveDI,
    .SPM.logMarco,
  ],
  interfaceDependencies: [
    
    .SPM.weaveDI,
    .SPM.composableArchitecture,
  ]
)
