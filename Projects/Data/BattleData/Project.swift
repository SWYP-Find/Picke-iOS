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
    .domain(.home, .interface),
    .domain(.battle, .interface),
    
    .service(.api),
    .data(.model),
    .service(.apiEndpoint),
    .network(implements: .networkModule),
    .network(implements: .networkHeader),
    .SPM.weaveDI,
    .SPM.logMarco,
    .SPM.composableArchitecture,
  ],
  sources: ["Sources/**"],
  hasTests: true
)
