import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .microModule(name: "AttendanceDomain"),
  bundleId: .appBundleID(name: ".AttendanceDomain"),
  product: .framework,
  settings: .settings(),
  dependencies: [
    .SPM.weaveDI,
    .SPM.composableArchitecture,
    .service(.api),
    .service(.apiEndpoint),
    .core(.network),
    .core(.network, .interface),
    .SPM.logMarco,
  ],
  interfaceDependencies: [.SPM.composableArchitecture]
)
