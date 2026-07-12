import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .module(name: "Presentation"),
  bundleId: .appBundleID(name: ".Presentation"),
  product: .staticFramework,
  settings: .settings(),
  dependencies: [
    .Presentation(implements: .Splash),
    .Presentation(implements: .Auth),
    .Presentation(implements: .Web),
    .Presentation(implements: .Home),
    .Presentation(implements: .Chat),
    .Presentation(implements: .Hifi),
    .Presentation(implements: .Battle),
    .Presentation(implements: .Profile),
    .Presentation(implements: .Notification),
  ],
  sources: ["Sources/**"]
)
