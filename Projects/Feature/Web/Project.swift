import Foundation
import ProjectDescription
import DependencyPlugin
import ProjectTemplatePlugin
import DependencyPackagePlugin

let project = Project.configure(
  moduleType: .feature(.web),
  bundleId: .appBundleID(name: ".Web"),
  settings: .settings(),
  dependencies: [
    .DesignSystem,
    .SPM.composableArchitecture,
    .Core(.PickeThirdParty),
  ]
)
