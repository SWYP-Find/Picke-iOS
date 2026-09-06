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
    .feature(.splash),
    .feature(.auth),
    .feature(.web),
    .feature(.home),
    .feature(.chat),
    .feature(.hifi),
    .feature(.battle),
    .feature(.profile),
    .feature(.notification),
  ],
  sources: ["Sources/**"]
)
