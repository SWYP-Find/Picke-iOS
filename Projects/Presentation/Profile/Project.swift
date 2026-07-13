import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .feature(.Profile),
  bundleId: .appBundleID(name: ".Profile"),
  product: .staticFramework,
  settings: .settings(),
  dependencies: [
    .Domain(.Profile, .interface),
    .Domain(.Auth),
    .Domain(.Battle, .interface),
    .Domain(implements: .UseCase),
    .Shared(implements: .Shared),
    .SPM.composableArchitecture,
    .SPM.tcaFlow,
    .SPM.kingfisher,
  ]
)
