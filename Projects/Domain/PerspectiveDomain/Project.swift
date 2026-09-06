import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .microModule(name: "PerspectiveDomain"),
  bundleId: .appBundleID(name: ".PerspectiveDomain"),
  settings: .settings(),
  dependencies: [
    .domain(.battle, .interface),
    .domain(.comment, .interface),
    .SPM.weaveDI,
    .SPM.composableArchitecture,
    .service(.api),
    .data(.model),
    .service(.apiEndpoint),
    .network(implements: .networkModule),
    .network(implements: .networkHeader),
    .SPM.logMarco,
  ],
  interfaceDependencies: [
    .domain(.battle, .interface),
    .domain(.comment, .interface),
    .SPM.weaveDI,
    .SPM.composableArchitecture,
  ]
)
