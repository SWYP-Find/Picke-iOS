import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .microModule(name: "HomeDomain"),
  bundleId: .appBundleID(name: ".HomeDomain"),
  product: .framework,
  settings: .settings(),
  dependencies: [
    .SPM.composableArchitecture,
    .domain(.auth, .interface),
    .service(.api),
    .service(.apiEndpoint),
    .core(.network),
    .core(.network, .interface),
    .SPM.logMarco,
  ],
  interfaceDependencies: [
    .SPM.composableArchitecture,
  ]
)
