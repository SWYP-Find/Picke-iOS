//
//  Project+Target.swift
//  ProjectTemplatePlugin
//
//  모듈 타입이 공유하는 Target 구성 helper.
//

import ProjectDescription

let suppressWarningsSettings: ProjectDescription.Settings = .settings(
  base: [
    // Xcode 26 의 XCTest 가 먼저 로드하는 애플 private `Sharing` 모듈과 충돌해 xctest 부팅이 깨진다.
    // Point-Free 구현은 `PickePointFreeSharing` 이름으로 빌드하고(Tuist/Package.swift),
    // 소스의 `import Sharing` 은 별칭으로 이어 붙인다.
    "OTHER_SWIFT_FLAGS": "$(inherited) -suppress-warnings -module-alias Sharing=PickePointFreeSharing",
    // Xcode 16 Explicitly Built Modules 비활성화.
    // (system 모듈(os_object)/WebKit pcm emit 실패 및 "implicit use of module files is disabled" 에러 회피)
    "SWIFT_ENABLE_EXPLICIT_MODULES": "NO",
    "_EXPERIMENTAL_SWIFT_EXPLICIT_MODULES": "NO",
    "CLANG_ENABLE_EXPLICIT_MODULES": "NO",
  ],
  // recommended 기본값은 타깃 레벨에 CODE_SIGN_IDENTITY = "iPhone Developer" 를 심어
  // 프로젝트 설정의 값을 덮는다. match 가 발급하는 건 Apple Development 이므로 이 키만 제외한다.
  defaultSettings: .recommended(excluding: ["CODE_SIGN_IDENTITY"])
)

extension Project {
  static func makeTestsTarget(
    name: String,
    bundleId: String,
    destinations: ProjectDescription.Destinations,
    deploymentTarget: ProjectDescription.DeploymentTargets,
    dependencies: [ProjectDescription.TargetDependency]
  ) -> Target {
    return .target(
      name: "\(name)Tests",
      destinations: destinations,
      product: .unitTests,
      bundleId: "\(bundleId).\(name)Tests",
      deploymentTargets: deploymentTarget,
      infoPlist: .default,
      buildableFolders: ["Tests"],
      dependencies: dependencies,
      settings: suppressWarningsSettings
    )
  }
}
