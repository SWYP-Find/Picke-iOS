import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .microModule(name: "Splash"),
  bundleId: .appBundleID(name: ".Splash"),
  product: .staticFramework,
  settings: .settings(),
  dependencies: [
    .ui(.designKit),
    .ui(.animation),
    .domain(.appUpdate, .interface),
    .core(.storage, .interface),
    .service(.analytics, .interface),
    .SPM.composableArchitecture,

    .core(.thirdParty),
  ]
)
