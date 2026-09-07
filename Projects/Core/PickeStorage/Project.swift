import Foundation

import DependencyPackagePlugin
import DependencyPlugin
import ProjectTemplatePlugin

import ProjectDescription

let project = Project.configure(
  moduleType: .microModule(name: "PickeStorage"),
  bundleId: .appBundleID(name: ".PickeStorage"),
  product: .framework,
  settings: .settings(),
  // Sources 가 ComposableArchitecture(DependencyKey)를 직접 import.
  // Security 는 시스템 프레임워크라 별도 의존성 선언이 필요 없고, Core 계층이라 Domain·Service 를 의존하지 않는다.
  dependencies: [
    .SPM.composableArchitecture,
    .SPM.sqliteData,
  ],
  interfaceDependencies: [
    .SPM.composableArchitecture,
    .SPM.sharing,
    .SPM.sqliteData,
  ]
)
