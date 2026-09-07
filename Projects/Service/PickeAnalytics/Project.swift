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
  // 관측 SDK 는 구현 타깃에만 붙인다 — 화면들은 Interface 만 의존하므로
  // Mixpanel·Sentry·Firebase 를 링크하지도, 이들이 바뀔 때 재컴파일되지도 않는다.
  // 네트워크 텔레메트리를 Mixpanel 로 흘려보내기 위해 PickeNetwork 를 의존한다.
  dependencies: [
    .core(.network),
    .SPM.firebaseCrashlytics,
    .SPM.mixpanel,
    .SPM.mixpanelSessionReplay,
    .SPM.sentry,
    .SPM.sentrySwiftUI,
    .SPM.logMarco,
  ],
  interfaceDependencies: [
    .SPM.composableArchitecture,
  ]
)
