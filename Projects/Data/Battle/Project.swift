import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .module(name: "BattleData"),
  bundleId: .appBundleID(name: ".BattleData"),
  product: .staticFramework,
  settings: .settings(),
  dependencies: [
    .Domain(.Home, .interface),
    .Domain(.Battle, .interface),
    .Domain(.Common, .interface),
    
    .api,
    .Data(implements: .Model),
    .apiEndpoint,
    .Network(implements: .NetworkModule),
    .Network(implements: .NetworkHeader),
    .SPM.weaveDI,
    .SPM.logMarco,
    .SPM.composableArchitecture,
  ],
  sources: ["Sources/**"],
  hasTests: true
)
