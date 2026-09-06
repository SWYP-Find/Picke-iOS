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
    .domain(.battle, .interface),
    .domain(.search, .interface),
    .domain(.home, .interface),
    
    .service(.api),
    .service(.apiEndpoint),
    .data(.model),
    .network(implements: .networkModule),
    .network(implements: .networkHeader),
    .SPM.logMarco,
    .SPM.composableArchitecture,
  ],
  sources: ["Sources/**"],
  hasTests: true
)
