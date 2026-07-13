import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .module(name: "Repository"),
  bundleId: .appBundleID(name: ".Repository"),
  product: .staticFramework,
  settings: .settings(),
  dependencies: [
    .Domain(.Common, .interface),
    .Domain(.Comment, .interface),
    .Domain(.Home, .interface),
    .Network(implements: .Networking),
    .Network(implements: .NetworkHeader),
    .Data(implements: .Service),
    .Data(implements: .Model),
    .Domain(implements: .DomainInterface),
    .Domain(.Auth, .interface),
    .SPM.alamofire,
    .SPM.composableArchitecture,
    .SPM.weaveDI,
    .SPM.logMarco,
    .SPM.mixpanel,
  ],
  sources: ["Sources/**"],
  hasTests: true
)
