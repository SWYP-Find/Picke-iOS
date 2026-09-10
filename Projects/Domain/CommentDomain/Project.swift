import Foundation

import DependencyPackagePlugin
import DependencyPlugin
import ProjectTemplatePlugin

import ProjectDescription

let project = Project.makeModule(
  name: "CommentDomain",
  bundleId: .appBundleID(name: ".CommentDomain"),
  product: .framework,
  settings: .settings(),
  dependencies: [
    .serviceAssembly,
    .domain(.battle, .interface),
    .SPM.composableArchitecture,
  ],
  hasTests: true,
  hasInterface: true,
  interfaceDependencies: [
    .domain(.battle, .interface),
    .SPM.composableArchitecture,
  ],
  hasTesting: false
)