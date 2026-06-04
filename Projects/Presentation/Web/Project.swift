import Foundation
import ProjectDescription
import DependencyPlugin
import ProjectTemplatePlugin
import DependencyPackagePlugin

let project = Project.makeAppModule(
  name: "Web",
  bundleId: .appBundleID(name: ".Web"),
  product: .staticFramework,
  settings: .settings(),
  dependencies: [
    .SPM.composableArchitecture,
    .Shared(implements: .Shared),
  ],
  sources: ["Sources/**"]
)