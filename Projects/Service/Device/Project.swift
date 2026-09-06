import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .microModule(name: "DeviceService"),
  bundleId: .appBundleID(name: ".DeviceService"),
  product: .staticFramework,
  settings: .settings(),
  dependencies: [
    .model,
    .apiEndpoint,
    .network(implements: .networkModule),
    .SPM.composableArchitecture,
    .SPM.logMarco,
  ],
  interfaceDependencies: [
    .SPM.composableArchitecture,
    .SPM.weaveDI,
  ]
)
