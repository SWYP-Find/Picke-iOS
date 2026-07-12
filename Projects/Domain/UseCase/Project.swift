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
