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
    .domain(.home, .interface),
    .SPM.weaveDI,
    .SPM.composableArchitecture,
    .domain(.battle, .interface),
    .service(.api),
    .service(.apiEndpoint),
    .data(.model),
    .network(implements: .networkModule),
    .network(implements: .networkHeader),
    .SPM.logMarco,
  ],
  interfaceDependencies: [
    .domain(.home, .interface),
    
    .SPM.weaveDI,
    .SPM.composableArchitecture,
  ]
)
