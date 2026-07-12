import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .module(name: "ProfileData"),
  bundleId: .appBundleID(name: ".ProfileData"),
  product: .staticFramework,
  settings: .settings(),
  dependencies: [
    .Domain(.Profile, .interface),
    .Data(implements: .API),
    .Data(implements: .Model),
    .Data(implements: .Service),
    .Data(implements: .Repository),
    .Network(implements: .NetworkHeader),
    .SPM.asyncMoya,
    .SPM.logMarco,
  ],
  sources: ["Sources/**"],
  hasTests: false
)
