import Foundation

import DependencyPackagePlugin
import DependencyPlugin
import ProjectTemplatePlugin

import ProjectDescription

// 애니메이션 라이브러리를 쓰는 뷰와 그 에셋만 둔다.
// SDWebImage 가 여기서 막히므로 DesignKit 과 화면 코드는 이 라이브러리를 모른다.
let project = Project.configure(
  moduleType: .module(name: "PickeAnimation"),
  bundleId: .appBundleID(name: ".PickeAnimation"),
  // 리소스 번들을 갖는 UI 모듈이라 동적 프레임워크로 둔다.
  product: .framework,
  settings: .settings(),
  dependencies: [
    .SPM.sdwebImageCore,
  ],
  sources: ["Sources/**"],
  resources: ["Resources/**"],
  hasTests: true
)
