import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .microModule(name: "SearchDomain"),
  bundleId: .appBundleID(name: ".SearchDomain"),
  product: .framework,
  settings: .settings(),
  dependencies: [
    .domain(.home, .interface),
    .SPM.composableArchitecture,
    .domain(.battle, .interface),
    .service(.api),
    .service(.apiEndpoint),
    .core(.network),
    .core(.network, .interface),
    .SPM.logMarco,
  ],
  interfaceDependencies: [
    .domain(.home, .interface),
    
    .SPM.composableArchitecture,
  ]
)
