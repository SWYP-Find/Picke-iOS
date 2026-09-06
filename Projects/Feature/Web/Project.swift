import Foundation
import ProjectDescription
import DependencyPlugin
import ProjectTemplatePlugin
import DependencyPackagePlugin

let project = Project.configure(
  moduleType: .microModule(name: "Web"),
  bundleId: .appBundleID(name: ".Web"),
  product: .staticFramework,
  settings: .settings(),
  dependencies: [
    .designSystem,
    .SPM.composableArchitecture,
    .core(.thirdParty),
  ]
)
