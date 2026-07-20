import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .feature(.Hifi),
  bundleId: .appBundleID(name: ".Hifi"),
  product: .staticFramework,
  settings: .settings(),
  dependencies: [
    .Shared(implements: .Shared),
    // 탐색 리스트 인라인 배너 광고 — 광고를 노출하는 화면만 명시적으로 의존한다.
    .Shared(implements: .AdKit),
    .Domain(.Home, .interface),
    .Domain(implements: .UseCase),
    .Domain(.Search, .interface),
    .Domain(.Notification, .interface),
    .SPM.composableArchitecture,
    .SPM.tcaFlow,
    .SPM.kingfisher,
  ]
)
