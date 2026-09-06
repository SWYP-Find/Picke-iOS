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
    .api,
    .Data(implements: .Model),
    .apiEndpoint,
    .Network(implements: .NetworkModule),
    .Network(implements: .NetworkHeader),
    .SPM.logMarco,
    .SPM.composableArchitecture,
  ],
  sources: ["Sources/**"],
  hasTests: true
)
