import Foundation

import DependencyPackagePlugin
import DependencyPlugin
import ProjectTemplatePlugin

import ProjectDescription

let project = Project.configure(
  moduleType: .module(name: "CoreAssembly"),
  bundleId: .appBundleID(name: ".CoreAssembly"),
  product: .staticFramework,
  settings: .settings(),
  // 최하위 기반 모듈의 구현을 한곳에서 묶는 조립 경계.
  dependencies: [
    .core(.thirdParty),
    .core(.logger),
    .core(.network),
    .core(.coreUtility),
    .core(.coreUI),
    .core(.storage, .implementation),
    .SPM.composableArchitecture,
  ],
  sources: ["Sources/**"],
  hasTests: true
)
