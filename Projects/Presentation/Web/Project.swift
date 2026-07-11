import Foundation
import ProjectDescription
import DependencyPlugin
import ProjectTemplatePlugin
import DependencyPackagePlugin

let project = Project.configure(
  moduleType: .feature(.Web),
  bundleId: .appBundleID(name: ".Web"),
  settings: .settings(),
  dependencies: [
    .SPM.composableArchitecture,
    .Shared(implements: .Shared),
  ]
)
