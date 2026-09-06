import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .microModule(name: "Chat"),
  bundleId: .appBundleID(name: ".Chat"),
  settings: .settings(),
  dependencies: [
    .service(.audioPlayer, .interface),
    .domain(.perspective, .interface),
    .designSystem,
    .core(.coreUtility),
    .service(.analytics, .interface),
    .domain(.battle, .interface),
    .domain(.home, .interface),
    .network(implements: .networkModule),

    .domain(.comment, .interface),
    .core(.thirdParty),
    // 큐레이션 리스트 상단 배너 광고 — 광고를 노출하는 화면만 명시적으로 의존한다.
    .service(.ad),
    .SPM.composableArchitecture,
    .SPM.tcaFlow,
    .SPM.kingfisher,
    .SPM.logMarco,
  ]
)
