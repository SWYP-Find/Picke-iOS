import Foundation

import DependencyPackagePlugin
import DependencyPlugin
import ProjectTemplatePlugin

import ProjectDescription

let project = Project.makeModule(
  name: "FeatureAssembly",
  bundleId: .appBundleID(name: ".FeatureAssembly"),
  product: .staticFramework,
  settings: .settings(),
  dependencies: [
    .feature(.splash, .implementation),
    .feature(.auth, .implementation),
    .feature(.web, .implementation),
    .feature(.home, .implementation),
    .feature(.chat, .implementation),
    .feature(.hifi, .implementation),
    .feature(.battle, .implementation),
    .feature(.profile, .implementation),
    .feature(.notification, .implementation),
    .feature(.ad, .implementation),
  ]
)