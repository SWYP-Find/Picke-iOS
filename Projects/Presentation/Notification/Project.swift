import Foundation
import ProjectDescription
import DependencyPlugin
import ProjectTemplatePlugin
import DependencyPackagePlugin

let project = Project.makeAppModule(
  name: "Notification",
  bundleId: .appBundleID(name: ".Notification"),
  product: .staticFramework,
  settings: .settings(),
  dependencies: [
    .Domain(implements: .UseCase),
    .Shared(implements: .Shared),
    .SPM.composableArchitecture,
    .SPM.tcaFlow,
  ],
  sources: ["Sources/**"]
)