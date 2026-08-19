import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .module(name: "NotificationData"),
  bundleId: .appBundleID(name: ".NotificationData"),
  product: .staticFramework,
  settings: .settings(),
  dependencies: [
    .Domain(.Notification, .interface),
    .Data(implements: .API),
    .Data(implements: .Model),
    .Data(implements: .Remote),
    .Network(implements: .NetworkModule),
    .Network(implements: .NetworkHeader),
    .SPM.logMarco,
  ],
  sources: ["Sources/**"],
  hasTests: true
)
