import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .feature(.Battle),
  bundleId: .appBundleID(name: ".Battle"),
  settings: .settings(),
  dependencies: [
    .Domain(.Common, .interface),
    .DesignSystem,
    .Core(.PickeFoundation),
    .Service(.Analytics, .interface),
    .Core(.PickeCore),
    .Domain(.Battle, .interface),
    
    .SPM.composableArchitecture,
    .SPM.tcaFlow,
    .SPM.kingfisher,
  ]
)
