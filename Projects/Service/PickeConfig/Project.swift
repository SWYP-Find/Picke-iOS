import Foundation

import DependencyPackagePlugin
import DependencyPlugin
import ProjectTemplatePlugin

import ProjectDescription

let project = Project.makeModule(
  name: "PickeConfig",
  bundleId: .appBundleID(name: ".PickeConfig"),
  product: .framework,
  settings: .settings(),
  // 외부 SDK 부팅만 안다. 심볼을 재수출하지 않아 의존하지 않은 모듈로 새지 않는다.
  dependencies: [
    .SPM.firebaseCrashlytics,
  ]
)
