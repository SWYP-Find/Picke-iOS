import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .feature(.Notification),
  bundleId: .appBundleID(name: ".Notification"),
  settings: .settings(),
  dependencies: [
    .Domain(.Notification, .interface),
    .Domain(implements: .UseCase),
    .Shared(implements: .Shared),
    .SPM.composableArchitecture,
    .SPM.tcaFlow,
  ]
)
