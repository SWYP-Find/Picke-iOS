import Foundation

import DependencyPackagePlugin
import DependencyPlugin
import ProjectTemplatePlugin

import ProjectDescription

let project = Project.configure(
  moduleType: .module(name: "PickeCoreLogger"),
  bundleId: .appBundleID(name: ".PickeCoreLogger"),
  product: .framework,
  settings: .settings(),
  dependencies: [
  ],
  sources: ["Sources/**"],
  hasTests: true
)
