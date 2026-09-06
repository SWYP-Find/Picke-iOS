import Foundation
import ProjectDescription
import DependencyPlugin
import ProjectTemplatePlugin
import DependencyPackagePlugin

let project = Project.configure(
  moduleType: .microModule(name: "Splash"),
  bundleId: .appBundleID(name: ".Splash"),
  settings: .settings(),
  dependencies: [
    .designSystem,
    .domain(.appUpdate, .interface),
    .core(.storage, .interface),
    .service(.analytics, .interface),
    .SPM.composableArchitecture,
    .SPM.sdwebImageCore,
    
    .core(.thirdParty),
  ]
)
