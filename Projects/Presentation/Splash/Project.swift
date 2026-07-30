import Foundation
import ProjectDescription
import DependencyPlugin
import ProjectTemplatePlugin
import DependencyPackagePlugin

let project = Project.configure(
  moduleType: .feature(.Splash),
  bundleId: .appBundleID(name: ".Splash"),
  settings: .settings(),
  dependencies: [
    .DesignSystem,
    .Domain(.AppUpdate, .interface),
    .Core(.PickeStorage, .interface),
    .Service(.Analytics, .interface),
    .SPM.composableArchitecture,
    .SPM.sdwebImageCore,
    
    .Core(.PickeCore),
  ]
)
