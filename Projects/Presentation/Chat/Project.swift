import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .feature(.Chat),
  bundleId: .appBundleID(name: ".Chat"),
  settings: .settings(),
  dependencies: [
    .Service(.AudioPlayer, .interface),
    .Domain(.Perspective, .interface),
    .DesignSystem,
    .Core(.PickeFoundation),
    .Service(.Analytics, .interface),
    .Domain(.Common, .interface),
    .Domain(.Battle, .interface),
    .Domain(.Home, .interface),
    
    .Domain(.Comment, .interface),
    .Core(.PickeCore),
    // 큐레이션 리스트 상단 배너 광고 — 광고를 노출하는 화면만 명시적으로 의존한다.
    .Service(.Ad),
    .SPM.composableArchitecture,
    .SPM.tcaFlow,
    .SPM.kingfisher,
    .SPM.logMarco,
  ]
)
