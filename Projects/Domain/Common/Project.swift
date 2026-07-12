import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .microModule(name: "CommonDomain"),
  bundleId: .appBundleID(name: ".CommonDomain"),
  product: .staticFramework,
  settings: .settings(),
  dependencies: [],
  interfaceDependencies: []
)
