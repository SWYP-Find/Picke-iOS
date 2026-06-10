import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

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
    .Presentation(implements: .Battle),
    .Presentation(implements: .Profile),
  ],
  sources: ["Sources/**"]
)
