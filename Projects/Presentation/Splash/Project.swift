import Foundation
import ProjectDescription
import DependencyPlugin
import ProjectTemplatePlugin
import DependencyPackagePlugin

let project = Project.makeAppModule(
  name: "Splash",
  bundleId: .appBundleID(name: ".Splash"),
  product: .staticFramework,
  settings: .settings(),
  dependencies: [
    .SPM.composableArchitecture,
    .Domain(implements: .UseCase),
    .Shared(implements: .Shared),
  ],
  sources: ["Sources/**"]
)
