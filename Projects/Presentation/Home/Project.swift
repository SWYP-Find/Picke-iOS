import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .feature(.Home),
  bundleId: .appBundleID(name: ".Home"),
  product: .staticFramework,
  settings: .settings(),
  dependencies: [
    .Domain(.Auth, .interface),
    .DesignSystem,
    .Service(.Analytics, .interface),
    .SPM.tcaFlow,
    .SPM.kingfisher,
    .Domain(.Attendance, .interface),
    .Domain(.Battle, .interface),
    .Domain(.Home, .interface),
    
    .Domain(.Notification, .interface),
    .Core(.PickeCore),
    // 홈 피드 중간 배너 광고 — 광고를 노출하는 화면만 명시적으로 의존한다.
    .Service(.Ad),
  ]
)
