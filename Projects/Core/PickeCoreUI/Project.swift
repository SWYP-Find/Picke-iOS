import Foundation

import DependencyPackagePlugin
import DependencyPlugin
import ProjectTemplatePlugin

import ProjectDescription

// 디자인 토큰을 모르는 순수 UIKit/SwiftUI 확장만 둔다.
// 토큰이나 리소스 번들을 참조하는 순간 PickeDesignKit 소속이다.
let project = Project.makeModule(
  name: "PickeCoreUI",
  bundleId: .appBundleID(name: ".PickeCoreUI"),
  product: .framework,
  settings: .settings(),
  dependencies: [
  ],
  hasTests: true
)