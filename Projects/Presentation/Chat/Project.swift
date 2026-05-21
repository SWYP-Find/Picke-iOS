import Foundation
import ProjectDescription
import DependencyPlugin
import ProjectTemplatePlugin
import DependencyPackagePlugin

let project = Project.makeAppModule(
  name: "Chat",
  bundleId: .appBundleID(name: ".Chat"),
  product: .staticFramework,
  settings: .settings(),
  dependencies: [
    .Domain(implements: .UseCase),
    .Shared(implements: .DesignSystem),
    .SPM.composableArchitecture,
    .SPM.tcaFlow,
  ],
  sources: ["Sources/**"]
)
