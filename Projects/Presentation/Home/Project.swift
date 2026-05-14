import Foundation
import ProjectDescription
import DependencyPlugin
import ProjectTemplatePlugin
import DependencyPackagePlugin

let project = Project.makeAppModule(
  name: "Home",
  bundleId: .appBundleID(name: ".Home"),
  product: .staticFramework,
  settings: .settings(),
  dependencies: [
    .SPM.logMarco,
    .SPM.tcaFlow,
    .Domain(implements: .UseCase),
    .Shared(implements: .DesignSystem),
  ],
  sources: ["Sources/**"]
)