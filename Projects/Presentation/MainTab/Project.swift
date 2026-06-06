import Foundation
import ProjectDescription
import DependencyPlugin
import ProjectTemplatePlugin
import DependencyPackagePlugin

let project = Project.makeAppModule(
  name: "MainTab",
  bundleId: .appBundleID(name: ".MainTab"),
  product: .staticFramework,
  settings: .settings(),
  dependencies: [
    .SPM.logMarco,
    .SPM.tcaFlow,
    .Domain(implements: .UseCase),
    .Shared(implements: .DesignSystem),
    .Presentation(implements: .Home),
    .Presentation(implements: .Hifi),
    .Presentation(implements: .Battle)
  ],
  sources: ["Sources/**"]
)
