import Foundation
import ProjectDescription
import DependencyPlugin
import ProjectTemplatePlugin
import DependencyPackagePlugin

let project = Project.makeAppModule(
  name: "Auth",
  bundleId: .appBundleID(name: ".Auth"),
  product: .staticFramework,
  settings: .settings(),
  dependencies: [
    .SPM.composableArchitecture,
    .SPM.tcaFlow,
    .Domain(implements: .UseCase),
    .Shared(implements: .Shared),
  ],
  sources: ["Sources/**"]
)
