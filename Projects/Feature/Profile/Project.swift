import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .feature(.profile),
  bundleId: .appBundleID(name: ".Profile"),
  product: .staticFramework,
  settings: .settings(),
  dependencies: [
    .DesignSystem,
    .Core(.PickeCoreUtility),
    .Core(.PickeStorage, .interface),
    .Service(.Device, .interface),
    .Service(.Analytics, .interface),
    .Domain(.Profile, .interface),
    .Domain(.Auth, .interface),
    .Domain(.Battle, .interface),
    .Domain(.Notification, .interface),

    .Core(.PickeThirdParty),
    .Service(.Ad), // 마이페이지 하단 배너 광고
    .SPM.composableArchitecture,
    .SPM.tcaFlow,
    .SPM.kingfisher,
  ],
  interfaceDependencies: [
    .Domain(.Profile, .interface),
  ]
)
