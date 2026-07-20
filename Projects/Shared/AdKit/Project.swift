import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .module(name: "AdKit"),
  bundleId: .appBundleID(name: ".AdKit"),
  // AdFitSDK.xcframework 가 DYLIB 이라 정적으로 감싸면 링크 경로가 꼬인다 — 동적 프레임워크로 둔다.
  product: .framework,
  settings: .settings(),
  dependencies: [
    // AdFit 배너 뷰(AdFitBannerView)가 쓰는 SDK. 광고를 노출하는 화면만 이 모듈을 의존하므로
    // 디자인 시스템(PickeDesignKit)이나 스토리북 데모가 광고 SDK를 끌고 오지 않는다.
    // AdFitSDK.xcframework 는 DYLIB 이라 여기 한 곳에서만 링크해도 앱에 단일 사본으로 임베드된다.
    .SPM.adFit,
  ],
  sources: ["Sources/**"],
  hasTests: false
)
