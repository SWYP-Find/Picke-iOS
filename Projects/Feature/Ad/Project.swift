import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .microModule(name: "Ad"),
  bundleId: .appBundleID(name: ".Ad"),
  // 정적 프레임워크로 둔다. GoogleMobileAds 는 Tuist 에서 동적으로 매핑돼 있고 GAD 심볼은
  // 그 안의 xcframework 에 있어, 이 모듈이 동적이면 자기 링크 시점에 GADRewardedAd/GADRequest 를
  // 못 풀고 실패한다(이전엔 UseCase 가 정적이라 앱 링크로 넘어가 해결됐다).
  product: .staticFramework,
  settings: .settings(),
  dependencies: [
    .SPM.adFit,
    .SPM.googleMobileAds,
    .service(.analytics, .interface),
  ],
  interfaceDependencies: [
    .SPM.composableArchitecture,
  ]
)
