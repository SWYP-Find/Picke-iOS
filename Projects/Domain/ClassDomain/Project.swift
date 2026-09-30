import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.makeModule(
  name: "ClassDomain",
  bundleId: .appBundleID(name: ".ClassDomain"),
  product: .framework,
  settings: .settings(),
  dependencies: [],
  hasTests: true,
  hasInterface: true,
  interfaceDependencies: [
    .SPM.composableArchitecture,
  ],
  hasTesting: false
)
