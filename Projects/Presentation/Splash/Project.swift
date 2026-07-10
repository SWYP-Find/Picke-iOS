import Foundation
import ProjectDescription
import DependencyPlugin
import ProjectTemplatePlugin
import DependencyPackagePlugin

let project = Project.configure(
  moduleType: .feature(name: "Splash"),
  bundleId: .appBundleID(name: ".Splash"),
  settings: .settings(),
  dependencies: [
    .SPM.composableArchitecture,
    .Domain(implements: .UseCase),
    .Shared(implements: .Shared),
  ]
)
