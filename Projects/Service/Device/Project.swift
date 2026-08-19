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
    .Data(implements: .Model),
    .Data(implements: .Remote),
    .Network(implements: .NetworkModule),
    .SPM.composableArchitecture,
    .SPM.logMarco,
  ],
  interfaceDependencies: [
    .SPM.composableArchitecture,
    .SPM.weaveDI,
  ]
)
