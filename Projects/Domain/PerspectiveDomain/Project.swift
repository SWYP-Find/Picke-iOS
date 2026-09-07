import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .microModule(name: "PerspectiveDomain"),
  bundleId: .appBundleID(name: ".PerspectiveDomain"),
  product: .framework,
  settings: .settings(),
  dependencies: [
    .domain(.battle, .interface),
    .domain(.comment, .interface),
    .SPM.composableArchitecture,
    .service(.api),
    .service(.apiEndpoint),
    .core(.coreUtility),
    .core(.network),
    .core(.network, .interface),
    .SPM.logMarco,
  ],
  interfaceDependencies: [
    .domain(.battle, .interface),
    .domain(.comment, .interface),
    .SPM.composableArchitecture,
  ]
)
