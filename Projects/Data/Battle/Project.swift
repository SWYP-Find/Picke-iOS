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
    .Domain(.Battle, .interface),
    .Domain(.Common, .interface),
    .Domain(implements: .Entity),
    .Data(implements: .API),
    .Data(implements: .Model),
    .Data(implements: .Service),
    .Data(implements: .Repository),
    .Network(implements: .NetworkHeader),
    .SPM.asyncMoya,
    .SPM.weaveDI,
    .SPM.logMarco,
  ],
  sources: ["Sources/**"],
  hasTests: false
)
