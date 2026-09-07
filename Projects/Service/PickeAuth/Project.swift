import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .microModule(name: "PickeAuth"),
  bundleId: .appBundleID(name: ".PickeAuth"),
  product: .staticFramework,
  settings: .settings(),
  dependencies: [
    .service(.apiEndpoint),
    .core(.network),
    .core(.storage),
    .core(.storage, .interface),
    .SPM.composableArchitecture,
    .SPM.logMarco,
  ],
  interfaceDependencies: [
    .core(.network, .interface),
    .SPM.composableArchitecture,
    .SPM.weaveDI,
  ]
)
