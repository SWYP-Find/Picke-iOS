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
    .Domain(implements: .UseCase),
    .Domain(.Search),
    .SPM.composableArchitecture,
    .SPM.tcaFlow,
    .SPM.kingfisher,
  ]
)
