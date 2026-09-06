import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .module(name: "CoreAssembly"),
  bundleId: .appBundleID(name: ".CoreAssembly"),
  product: .staticFramework,
  settings: .settings(),
  // 최하위 기반 모듈의 구현을 한곳에서 묶는 조립 경계.
  dependencies: [
    .Core(.PickeCore),
    .Core(.PickeFoundation),
    .Core(.PickeStorage, .implementation),
  ],
  sources: ["Sources/**"],
  hasTests: false
)
