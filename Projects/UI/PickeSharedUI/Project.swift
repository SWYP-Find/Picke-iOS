import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

// 외부 라이브러리에 기대는 공용 UI 만 둔다.
// PickeDesignKit 은 토큰과 순수 컴포넌트만 갖고 라이브러리를 모른다.
let project = Project.configure(
  moduleType: .module(name: "PickeSharedUI"),
  bundleId: .appBundleID(name: ".PickeSharedUI"),
  product: .staticFramework,
  settings: .settings(),
  dependencies: [
    .ui(.designKit),
    .SPM.composableArchitecture,
    .SPM.kingfisher,
  ],
  sources: ["Sources/**"],
  hasTests: true
)
