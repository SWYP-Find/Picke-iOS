import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .microModule(name: "ProfileDomain"),
  bundleId: .appBundleID(name: ".ProfileDomain"),
  product: .framework,
  settings: .settings(),
  dependencies: [
    .SPM.composableArchitecture,
    .service(.api),
    .service(.apiEndpoint),
    .core(.coreUtility),
    .core(.network),
    .core(.network, .interface),
    .SPM.logMarco,
  ],
  interfaceDependencies: [
    .SPM.composableArchitecture,
  ]
)
