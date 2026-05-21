import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

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
    .SPM.kingfisher,
    .SPM.logMarco,
  ],
  sources: ["Sources/**"]
)
