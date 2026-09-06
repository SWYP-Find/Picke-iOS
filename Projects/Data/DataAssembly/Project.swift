import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .module(name: "DataAssembly"),
  bundleId: .appBundleID(name: ".DataAssembly"),
  product: .staticFramework,
  settings: .settings(),
  dependencies: [
    .Data(.AppUpdate),
    .Data(implements: .Model),
    .apiEndpoint,
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
