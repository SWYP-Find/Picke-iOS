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
    .Domain(implements: .Entity),
    .Domain(implements: .DomainInterface),
    .Domain(implements: .UseCase),
    .Domain(.Search, .interface),
    .Domain(.Search),
    .Domain(.Notification, .interface),
    .Domain(.Notification),
    .Domain(.Profile),
  ],
  sources: ["Sources/**"]
)
