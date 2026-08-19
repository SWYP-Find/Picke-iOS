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
