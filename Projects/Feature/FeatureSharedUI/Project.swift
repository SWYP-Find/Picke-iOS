import Foundation

import DependencyPackagePlugin
import DependencyPlugin
import ProjectTemplatePlugin

import ProjectDescription

let project = Project.makeModule(
  name: "FeatureSharedUI",
  bundleId: .appBundleID(name: ".FeatureSharedUI"),
  product: .staticFramework,
  settings: .settings(),
  // 피처 여러 곳이 함께 쓰는 화면 조각. 피처끼리 서로의 구현을 직접 물지 않게 여기로 모은다.
  dependencies: [
    .SPM.adFit,
  ]
)
