import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .module(name: "DomainAssembly"),
  bundleId: .appBundleID(name: ".DomainAssembly"),
  product: .staticFramework,
  settings: .settings(),
  dependencies: [
    .Domain(.Common),
    .Domain(.Attendance),
    .Domain(.Auth),
    .Domain(.Battle),
    .Domain(.Search),
    .Domain(.Comment),
    .Domain(.Home),
    .Domain(.Notification),
    .Domain(.Perspective),
    .Domain(.Profile),
  ],
  sources: ["Sources/**"]
)
