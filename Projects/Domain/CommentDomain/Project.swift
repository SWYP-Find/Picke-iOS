import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .microModule(name: "CommentDomain"),
  bundleId: .appBundleID(name: ".CommentDomain"),
  product: .framework,
  settings: .settings(),
  dependencies: [
    .domain(.battle, .interface),
    .SPM.composableArchitecture,
    .service(.api),
    .service(.apiEndpoint),
    .core(.network),
    .core(.network, .interface),
    .SPM.logMarco,
  ],
  interfaceDependencies: [
    .domain(.battle, .interface),
    .SPM.composableArchitecture,
  ]
)
