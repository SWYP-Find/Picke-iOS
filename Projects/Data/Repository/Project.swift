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
    .Core(.PickeStorage, .interface),
    .Domain(.AppUpdate, .interface),
    .Service(.Device, .interface),
    .Domain(.Common, .interface),
    .Domain(.Comment, .interface),
    .Domain(.Home, .interface),
    .Network(implements: .Networking),
    .Network(implements: .NetworkHeader),
    .Data(implements: .Remote),
    .Data(implements: .Model),
    .Service(.AudioPlayer),
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
