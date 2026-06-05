import Foundation
import ProjectDescription
import DependencyPlugin
import ProjectTemplatePlugin
import DependencyPackagePlugin

let project = Project.makeAppModule(
  name: "Battle",
  bundleId: .appBundleID(name: ".Battle"),
  product: .staticFramework,
  settings: .settings(),
  dependencies: [
    .Presentation(implements: .Chat),
    .Shared(implements: .Shared),
    .SPM.composableArchitecture,
    .SPM.tcaFlow,
  ],
  sources: ["Sources/**"]
)