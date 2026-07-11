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
    .Network(implements: .Networking),
    .Network(implements: .Foundations),
    .Data(implements: .Service),
    .Data(implements: .Model),
    .Domain(implements: .DomainInterface),
    .SPM.asyncMoya,
    .SPM.composableArchitecture,
    .SPM.weaveDI,
    .SPM.logMarco,
    .SPM.mixpanel,
    .SPM.googleSignIn,
  ],
  sources: ["Sources/**"],
  hasTests: true
)
