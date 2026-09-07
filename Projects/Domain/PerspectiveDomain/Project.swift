import Foundation

import DependencyPackagePlugin
import DependencyPlugin
import ProjectTemplatePlugin

import ProjectDescription

let project = Project.configure(
  moduleType: .microModule(name: "PerspectiveDomain"),
  bundleId: .appBundleID(name: ".PerspectiveDomain"),
  product: .framework,
  settings: .settings(),
  dependencies: [
    .serviceAssembly,
    .domain(.battle, .interface),
    .domain(.comment, .interface),
  ],
  interfaceDependencies: [
    .domain(.battle, .interface),
    .domain(.comment, .interface),
    .SPM.composableArchitecture,
  ]
)
