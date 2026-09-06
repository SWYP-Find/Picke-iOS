import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .microModule(name: "Home"),
  bundleId: .appBundleID(name: ".Home"),
  product: .staticFramework,
  settings: .settings(),
  dependencies: [
    .domain(.auth, .interface),
    .ui(.designKit),
    .ui(.sharedUI),
    .service(.analytics, .interface),
    .SPM.tcaFlow,
    .SPM.kingfisher,
    .domain(.attendance, .interface),
    .domain(.battle, .interface),
    .domain(.home, .interface),
    
    .domain(.notification, .interface),
    .core(.thirdParty),
    // 홈 피드 중간 배너 광고 — 광고를 노출하는 화면만 명시적으로 의존한다.
    .feature(.ad),
  ]
)
