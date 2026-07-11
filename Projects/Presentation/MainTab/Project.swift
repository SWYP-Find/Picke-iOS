import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .feature(name: "MainTab"),
  bundleId: .appBundleID(name: ".MainTab"),
  product: .staticFramework,
  settings: .settings(),
  dependencies: [
    .Shared(implements: .DesignSystem),
  ]
)
