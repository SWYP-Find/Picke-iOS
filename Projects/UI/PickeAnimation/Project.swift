import Foundation

import DependencyPackagePlugin
import DependencyPlugin
import ProjectTemplatePlugin

import ProjectDescription

// 애니메이션 라이브러리를 쓰는 뷰와 그 에셋만 둔다.
// SDWebImage 가 여기서 막히므로 DesignKit 과 화면 코드는 이 라이브러리를 모른다.
let project = Project.makeModule(
  name: "PickeAnimation",
  bundleId: .appBundleID(name: ".PickeAnimation"),
  product: .framework,
  settings: .settings(),
  dependencies: [
    .SPM.sdwebImageCore,
  ],
  resources: ["Resources/**"],
  hasTests: true
)