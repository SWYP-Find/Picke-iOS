import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .module(name: "PickeCore"),
  bundleId: .appBundleID(name: ".PickeCore"),
  product: .framework,
  settings: .settings(),
  dependencies: [
    .Core(.PickeFoundation),
    .DesignSystem,
    .SPM.composableArchitecture,
    .SPM.tcaFlow,
    .SPM.sdwebImage,
  ],
  sources: ["Sources/**"],
  hasTests: false
)
