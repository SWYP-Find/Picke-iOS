import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .feature(.battle),
  bundleId: .appBundleID(name: ".Battle"),
  settings: .settings(),
  dependencies: [
    .DesignSystem,
    .Core(.PickeCoreUtility),
    .Service(.Analytics, .interface),
    .Core(.PickeCore),
    .Domain(.Battle, .interface),
    
    .SPM.composableArchitecture,
    .SPM.tcaFlow,
    .SPM.kingfisher,
  ]
)
