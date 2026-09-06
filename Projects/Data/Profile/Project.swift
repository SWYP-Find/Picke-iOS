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
    .Data(implements: .Remote),
    .Network(implements: .NetworkModule),
    .Network(implements: .NetworkHeader),
    .SPM.logMarco,
    .SPM.composableArchitecture,
  ],
  sources: ["Sources/**"],
  hasTests: true
)
