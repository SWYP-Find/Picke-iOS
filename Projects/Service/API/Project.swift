import Foundation

import DependencyPackagePlugin
import DependencyPlugin
import ProjectTemplatePlugin

import ProjectDescription

let project = Project.makeModule(
  name: "API",
  bundleId: .appBundleID(name: ".API"),
  product: .framework,
  settings: .settings(),
  dependencies: [
    .core(.network, .interface),
  ],
  hasTests: true
)