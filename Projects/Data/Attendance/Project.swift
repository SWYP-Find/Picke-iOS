import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .module(name: "AttendanceData"),
  bundleId: .appBundleID(name: ".AttendanceData"),
  product: .staticFramework,
  settings: .settings(),
  dependencies: [
    .Domain(.Attendance, .interface),
    .Data(implements: .API),
    .Data(implements: .Model),
    .Data(implements: .Remote),
    .Data(implements: .Repository),
    .Network(implements: .NetworkHeader),
    .SPM.logMarco,
  ],
  sources: ["Sources/**"],
  hasTests: true
)
