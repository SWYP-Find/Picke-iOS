import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .module(name: "FeatureAssembly"),
  bundleId: .appBundleID(name: ".FeatureAssembly"),
  product: .staticFramework,
  settings: .settings(),
  dependencies: [
    .feature(implements: .splash),
    .feature(implements: .auth),
    .feature(implements: .web),
    .feature(implements: .home),
    .feature(implements: .chat),
    .feature(implements: .hifi),
    .feature(implements: .battle),
    .feature(implements: .profile),
    .feature(implements: .notification),
  ],
  sources: ["Sources/**"]
)
