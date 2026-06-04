import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.makeAppModule(
  name: "Hifi",
  bundleId: .appBundleID(name: ".Hifi"),
  product: .staticFramework,
  settings: .settings(),
  dependencies: [
    .Presentation(implements: .Chat),
    .Shared(implements: .Shared),
    .Domain(implements: .UseCase),
    .SPM.composableArchitecture,
    .SPM.tcaFlow,
    .SPM.kingfisher,
  ],
  sources: ["Sources/**"]
)
