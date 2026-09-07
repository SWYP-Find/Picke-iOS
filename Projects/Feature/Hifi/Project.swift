import Foundation

import DependencyPackagePlugin
import DependencyPlugin
import ProjectTemplatePlugin

import ProjectDescription

let project = Project.makeModule(
  name: "Hifi",
  bundleId: .appBundleID(name: ".Hifi"),
  product: .staticFramework,
  settings: .settings(),
  dependencies: [
    .domain(.battle, .interface),
    .ui(.designKit),
    .ui(.sharedUI),
    .core(.coreUtility),
    .service(.analytics, .interface),
    // 탐색 리스트 인라인 배너 광고 — 광고를 노출하는 화면만 명시적으로 의존한다.
    .feature(.featureSharedUI, .implementation),
    .domain(.home, .interface),
    .domain(.search, .interface),
    .domain(.notification, .interface),
    .SPM.composableArchitecture,
    .SPM.kingfisher,
  ],
  hasTests: true,
  hasInterface: true,
  hasTesting: false
)