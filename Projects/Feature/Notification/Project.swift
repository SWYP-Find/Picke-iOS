import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .feature(.notification),
  bundleId: .appBundleID(name: ".Notification"),
  settings: .settings(),
  dependencies: [
    .DesignSystem,
    .Core(.PickeFoundation),
    .Service(.Analytics, .interface),
    .Domain(.Notification, .interface),
    
    .Core(.PickeCore),
    .SPM.composableArchitecture,
    .SPM.tcaFlow,
  ]
)
