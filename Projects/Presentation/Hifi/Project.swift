import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .feature(.Hifi),
  bundleId: .appBundleID(name: ".Hifi"),
  product: .staticFramework,
  settings: .settings(),
  dependencies: [
    .Shared(implements: .Shared),
    .Domain(.Home, .interface),
    .Domain(implements: .UseCase),
    .Domain(.Search, .interface),
    .SPM.composableArchitecture,
    .SPM.tcaFlow,
    .SPM.kingfisher,
  ]
)
