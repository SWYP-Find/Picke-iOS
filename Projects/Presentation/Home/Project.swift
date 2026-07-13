import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .feature(.Home),
  bundleId: .appBundleID(name: ".Home"),
  product: .staticFramework,
  settings: .settings(),
  dependencies: [
    .SPM.tcaFlow,
    .SPM.kingfisher,
    .Domain(.Battle, .interface),
    .Domain(.Home, .interface),
    .Domain(implements: .UseCase),
    .Domain(.Notification, .interface),
    .Shared(implements: .Shared),
  ]
)
