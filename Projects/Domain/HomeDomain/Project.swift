import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .microModule(name: "HomeDomain"),
  bundleId: .appBundleID(name: ".HomeDomain"),
  settings: .settings(),
  dependencies: [
    .SPM.weaveDI,
    .SPM.composableArchitecture,
    .domain(.auth, .interface),
    .service(.api),
    .data(.model),
    .service(.apiEndpoint),
    .network(implements: .networkModule),
    .network(implements: .networkHeader),
    .SPM.logMarco,
  ],
  interfaceDependencies: [
    .SPM.weaveDI,
    .SPM.composableArchitecture,
  ]
)
