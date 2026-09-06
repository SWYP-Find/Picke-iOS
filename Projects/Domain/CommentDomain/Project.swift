import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .microModule(name: "CommentDomain"),
  bundleId: .appBundleID(name: ".CommentDomain"),
  settings: .settings(),
  dependencies: [
    .domain(.battle, .interface),
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
    .SPM.weaveDI,
    .SPM.composableArchitecture,
  ]
)
