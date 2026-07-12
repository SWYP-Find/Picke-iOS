import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .feature(.Chat),
  bundleId: .appBundleID(name: ".Chat"),
  settings: .settings(),
  dependencies: [
    .Domain(.Common, .interface),
    .Domain(implements: .UseCase),
    .Shared(implements: .Shared),
    .SPM.composableArchitecture,
    .SPM.tcaFlow,
    .SPM.kingfisher,
    .SPM.logMarco,
  ]
)
