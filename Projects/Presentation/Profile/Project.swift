import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.makeAppModule(
  name: "Profile",
  bundleId: .appBundleID(name: ".Profile"),
  product: .staticFramework,
  settings: .settings(),
  dependencies: [
    .Domain(implements: .UseCase),
    .Shared(implements: .Shared),
    .SPM.composableArchitecture,
    .SPM.tcaFlow,
    .Presentation(implements: .Web),
  ],
  sources: ["Sources/**"]
)
