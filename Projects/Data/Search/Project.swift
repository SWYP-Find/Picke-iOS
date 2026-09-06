import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .module(name: "SearchData"),
  bundleId: .appBundleID(name: ".SearchData"),
  product: .staticFramework,
  settings: .settings(),
  dependencies: [
    .Domain(.Battle, .interface),
    .Domain(.Search, .interface),
    .Domain(.Common, .interface),
    .Domain(.Home, .interface),
    
    .api,
    .Data(implements: .Model),
    .Network(implements: .NetworkModule),
    .Network(implements: .NetworkHeader),
    .SPM.logMarco,
    .SPM.composableArchitecture,
  ],
  sources: ["Sources/**"],
  hasTests: true
)
