//
//  Project+Target.swift
//  ProjectTemplatePlugin
//
//  모듈 타입이 공유하는 Target 구성 helper.
//

import ProjectDescription

let suppressWarningsSettings: ProjectDescription.Settings = .settings(
  base: [
    "OTHER_SWIFT_FLAGS": "$(inherited) -suppress-warnings",
    // Xcode 16 Explicitly Built Modules 비활성화.
    // (system 모듈(os_object)/WebKit pcm emit 실패 및 "implicit use of module files is disabled" 에러 회피)
    "SWIFT_ENABLE_EXPLICIT_MODULES": "NO",
    "_EXPERIMENTAL_SWIFT_EXPLICIT_MODULES": "NO",
    "CLANG_ENABLE_EXPLICIT_MODULES": "NO",
  ]
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
