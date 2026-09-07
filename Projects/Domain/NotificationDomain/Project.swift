import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .microModule(name: "NotificationDomain"),
  bundleId: .appBundleID(name: ".NotificationDomain"),
  product: .framework,
  settings: .settings(),
  dependencies: [
    .SPM.composableArchitecture,
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
