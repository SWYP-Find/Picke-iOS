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
    .SPM.tcaFlow,
    .SPM.kingfisher,
    .Domain(.Attendance, .interface),
    .Domain(.Battle, .interface),
    .Domain(.Home, .interface),
    .Domain(implements: .UseCase),
    .Domain(.Notification, .interface),
    .Shared(implements: .Shared),
    // 홈 피드 중간 배너 광고 — 광고를 노출하는 화면만 명시적으로 의존한다.
    .Shared(implements: .AdKit),
  ]
)
