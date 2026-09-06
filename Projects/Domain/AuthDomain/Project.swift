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
    .service(.api),
    .data(.model),
    .service(.apiEndpoint),
    .core(.network),
    .core(.network, .interface),
    .SPM.googleSignIn,
  ],
  interfaceDependencies: [
    
    .SPM.weaveDI,
    .SPM.composableArchitecture,
  ]
)
