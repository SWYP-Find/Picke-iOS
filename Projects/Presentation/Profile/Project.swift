import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .feature(.Profile),
  bundleId: .appBundleID(name: ".Profile"),
  product: .staticFramework,
  settings: .settings(),
  dependencies: [
    .Domain(.Common, .interface),
    .DesignSystem,
    .Core(.PickeFoundation),
    .Core(.PickeStorage, .interface),
    .Service(.Device, .interface),
    .Service(.Analytics, .interface),
    .Domain(.Profile, .interface),
    .Domain(.Auth, .interface),
    .Domain(.Battle, .interface),
    .Domain(.Notification, .interface),
    
    .Core(.PickeCore),
    .Service(.Ad), // 마이페이지 하단 배너 광고
    .SPM.composableArchitecture,
    .SPM.tcaFlow,
    .SPM.kingfisher,
  ]
)
