import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .module(name: "Domain"),
  bundleId: .appBundleID(name: ".Domain"),
  product: .staticFramework,
  settings: .settings(),
  dependencies: [
    .Domain(.Common, .interface),
    .Domain(.Common),
    .Domain(implements: .Entity),
    .Domain(implements: .DomainInterface),
    .Domain(implements: .UseCase),
    .Domain(.Auth, .interface),
    .Domain(.Auth),
    .Domain(.Search, .interface),
    .Domain(.Search),
    .Domain(.Comment, .interface),
    .Domain(.Comment),
    .Domain(.Home, .interface),
    .Domain(.Home),
    .Domain(.Notification, .interface),
    .Domain(.Notification),
    .Domain(.Profile),
  ],
  sources: ["Sources/**"]
)
