import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .feature(.Auth),
  bundleId: .appBundleID(name: ".Auth"),
  settings: .settings(),
  dependencies: [
    .SPM.composableArchitecture,
    .SPM.tcaFlow,
    .Domain(implements: .UseCase),
    .Shared(implements: .Shared),
  ]
)
