import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.makeAppModule(
  name: "Battle",
  bundleId: .appBundleID(name: ".Battle"),
  product: .staticFramework,
  settings: .settings(),
  dependencies: [
    .Presentation(implements: .Chat),
    .Shared(implements: .Shared),
    .Domain(implements: .UseCase),
    .SPM.composableArchitecture,
    .SPM.tcaFlow,
  ],
  sources: ["Sources/**"]
)
