import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .feature(.auth),
  bundleId: .appBundleID(name: ".Auth"),
  settings: .settings(),
  dependencies: [
    .DesignSystem,
    .Service(.Analytics, .interface),
    .SPM.composableArchitecture,
    .SPM.tcaFlow,
    .Domain(.Auth, .interface),
    
    
    .Core(.PickeThirdParty),
  ]
)
