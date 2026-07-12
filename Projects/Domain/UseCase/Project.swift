import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .module(name: "UseCase"),
  bundleId: .appBundleID(name: ".UseCase"),
  product: .staticFramework,
  settings: .settings(),
  dependencies: [
    .Domain(.Common, .interface),
    .Domain(.Comment, .interface),
    .Domain(.Home, .interface),
    .Domain(implements: .DomainInterface),
    .Domain(.Profile),
    .SPM.composableArchitecture,
    .SPM.weaveDI,
    .SPM.mixpanel,
    .SPM.mixpanelSessionReplay,
    .SPM.googleMobileAds,
  ],
  sources: ["Sources/**"],
  hasTests: true
)
