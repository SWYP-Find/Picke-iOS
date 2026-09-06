import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

// 디자인 토큰을 모르는 순수 UIKit/SwiftUI 확장만 둔다.
// 토큰이나 리소스 번들을 참조하는 순간 PickeDesignKit 소속이다.
let project = Project.configure(
  moduleType: .module(name: "PickeCoreUI"),
  bundleId: .appBundleID(name: ".PickeCoreUI"),
  // 동적 프레임워크. 동적인 PickeDesignKit 이 링크하므로 정적으로 두면
  // 앱과 DesignKit 양쪽에 중복으로 박힌다.
  product: .framework,
  settings: .settings(),
  dependencies: [
  ],
  sources: ["Sources/**"],
  hasTests: false
)
