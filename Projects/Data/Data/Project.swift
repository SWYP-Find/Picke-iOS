import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .module(name: "Data"),
  bundleId: .appBundleID(name: ".Data"),
  product: .staticFramework,
  settings: .settings(),
  dependencies: [
    .Data(implements: .API),
    .Data(implements: .Model),
    .Data(implements: .Remote),
    .Data(implements: .Repository),
    .Data(.Attendance),
    .Data(.Auth),
    .Data(.Battle),
    .Data(.Search),
    .Data(.Comment),
    .Data(.Home),
    .Data(.Notification),
    .Data(.Perspective),
    .Data(.Profile),
  ],
  sources: ["Sources/**"]
)
