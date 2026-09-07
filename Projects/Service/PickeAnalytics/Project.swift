import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .microModule(name: "PickeAnalytics"),
  bundleId: .appBundleID(name: ".PickeAnalytics"),
  product: .staticFramework,
  settings: .settings(),
  // 분석 SDK 는 구현 타깃에만 붙인다 — 화면들은 Interface 만 의존하므로
  // Mixpanel·Sentry 를 링크하지도, 이들이 바뀔 때 재컴파일되지도 않는다.
  dependencies: [
    .SPM.mixpanel,
    .SPM.mixpanelSessionReplay,
    .SPM.sentry,
    .SPM.logMarco,
  ],
  interfaceDependencies: [
    .SPM.composableArchitecture,
  ]
)
